// hotplug-emu — udev hotplug → emulator controller-config bridge for GOW (Cumulus EP)
//
// GOW's fake-udev broadcasts controller plug/unplug as NETLINK_KOBJECT_UEVENT
// netlink events on the udev multicast group (group 2). This program listens
// for those events, resolves what was plugged in from sysfs, and writes the
// controller-emulation config files for the emulators in the container.
//
// Modes:
//   hotplug-emu daemon               background listener (started by prelaunch script)
//   hotplug-emu apply [--all]       one-shot: apply current controller state now
//   hotplug-emu status              show detected controller + applied state
//   hotplug-emu selftest-plug       emit a synthetic "add" uevent (testing)
//   hotplug-emu selftest-unplug     emit a synthetic "remove" uevent (testing)
//
// Environment:
//   HPEMU_HOME   app user home (default /home/retro)
//   HPEMU_RUNDIR run dir for state (default /run/hotplug-emu)
//   HPEMU_PORTS  dolphin managed SI ports, comma list (default "0,1,2,3")
//
// Zero dependencies (libc only).
// Build: g++ -std=c++20 -O2 -static -o hotplug-emu hotplug-emu.cpp

#include <arpa/inet.h>
#include <cctype>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <linux/netlink.h>
#include <net/if.h>
#include <poll.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <vector>

// ---------------------------------------------------------------------------
// logging
// ---------------------------------------------------------------------------
static void log_msg(const std::string& msg)
{
    char ts[64];
    time_t now = time(nullptr);
    struct tm tmv;
    if (gmtime_r(&now, &tmv))
        strftime(ts, sizeof(ts), "%Y-%m-%dT%H:%M:%SZ", &tmv);
    else
        snprintf(ts, sizeof(ts), "1970-01-01T00:00:00Z");
    fprintf(stderr, "%s hotplug-emu: %s\n", ts, msg.c_str());
    fflush(stderr);
}

static void logf(const char* fmt, ...)
{
    char buf[4096];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    log_msg(buf);
}

// ---------------------------------------------------------------------------
// config
// ---------------------------------------------------------------------------
struct Cfg
{
    std::string home;
    std::string rundir;
    std::vector<int> ports;

    static Cfg load()
    {
        Cfg c;
        if (const char* h = getenv("HPEMU_HOME"))
            c.home = h;
        else
            c.home = "/home/retro";
        if (const char* r = getenv("HPEMU_RUNDIR"))
            c.rundir = r;
        else
            c.rundir = "/run/hotplug-emu";
        std::string p = "0,1,2,3";
        if (const char* e = getenv("HPEMU_PORTS"))
            p = e;
        size_t i = 0;
        while (i < p.size())
        {
            while (i < p.size() && (p[i] == ' ' || p[i] == ','))
                i++;
            size_t j = i;
            while (j < p.size() && (p[j] == ' ' || p[j] == ','))
                j++;
            if (i == j)
                break;
            std::string tok = p.substr(i, j - i);
            bool ok = !tok.empty();
            for (char ch : tok)
                if (ch < '0' || ch > '9')
                    ok = false;
            if (ok)
            {
                int v = std::atoi(tok.c_str());
                if (v >= 0 && v <= 3)
                    c.ports.push_back(v);
            }
            i = j;
        }
        if (c.ports.empty())
            c.ports = {0, 1, 2, 3};
        std::vector<int> dedup;
        for (int v : c.ports)
            if (std::find(dedup.begin(), dedup.end(), v) == dedup.end())
                dedup.push_back(v);
        c.ports = dedup;
        return c;
    }
};

// ---------------------------------------------------------------------------
// small fs helpers
// ---------------------------------------------------------------------------
static bool read_file(const std::string& path, std::string& out)
{
    int fd = ::open(path.c_str(), O_RDONLY | O_CLOEXEC);
    if (fd < 0)
        return false;
    out.clear();
    std::vector<char> buf(65536);
    for (;;)
    {
        ssize_t n = ::read(fd, buf.data(), buf.size());
        if (n < 0)
        {
            if (errno == EINTR)
                continue;
            ::close(fd);
            return false;
        }
        if (n == 0)
            break;
        out.append(buf.data(), static_cast<size_t>(n));
    }
    ::close(fd);
    return true;
}

static bool stat_path(const std::string& path, struct stat& st)
{
    return ::stat(path.c_str(), &st) == 0;
}

static bool mkdir_p(const std::string& path)
{
    if (path.empty() || path == "/")
        return true;
    struct stat st;
    if (::stat(path.c_str(), &st) == 0)
        return S_ISDIR(st.st_mode);
    size_t sl = path.find_last_of('/');
    std::string parent = (sl == 0) ? "/" : path.substr(0, sl);
    if (!mkdir_p(parent))
        return false;
    if (::mkdir(path.c_str(), 0755) != 0 && errno != EEXIST)
    {
        logf("mkdir %s: %s", path.c_str(), strerror(errno));
        return false;
    }
    return true;
}

static std::string dirname_of(const std::string& path)
{
    size_t sl = path.find_last_of('/');
    if (sl == 0)
        return "/";
    if (sl == std::string::npos)
        return ".";
    return path.substr(0, sl);
}

static void choose_owner(const std::string& home, const std::string& path, uid_t& uid, gid_t& gid)
{
    uid = 1000;
    gid = 1000;
    struct stat st;
    if (::stat(home.c_str(), &st) == 0)
    {
        uid = st.st_uid;
        gid = st.st_gid;
        return;
    }
    if (stat_path(path, st))
    {
        uid = st.st_uid;
        gid = st.st_gid;
        return;
    }
}

static bool write_atomic(const std::string& path, const std::string& contents, uid_t owner_uid, gid_t owner_gid, mode_t mode = 0644)
{
    std::string tmp = path + ".tmp." + std::to_string(getpid());
    int fd = ::open(tmp.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, mode);
    if (fd < 0)
    {
        logf("write_atomic: open %s: %s", tmp.c_str(), strerror(errno));
        return false;
    }
    bool ok = true;
    size_t off = 0;
    while (off < contents.size())
    {
        ssize_t n = ::write(fd, contents.data() + off, contents.size() - off);
        if (n < 0)
        {
            if (errno == EINTR)
                continue;
            ok = false;
            break;
        }
        off += static_cast<size_t>(n);
    }
    if (ok && ::fsync(fd) != 0)
        ok = false;
    if (ok)
    {
        ::fchown(fd, owner_uid, owner_gid);
        ::fchmod(fd, mode);
    }
    ::close(fd);
    if (ok && ::rename(tmp.c_str(), path.c_str()) != 0)
        ok = false;
    if (!ok)
    {
        ::unlink(tmp.c_str());
        logf("write_atomic: %s: %s", path.c_str(), strerror(errno));
        return false;
    }
    return true;
}

static std::string trim(const std::string& s)
{
    size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos)
        return "";
    size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

static std::string realpath_or_empty(const std::string& path)
{
    char buf[4096];
    if (::realpath(path.c_str(), buf) == nullptr)
        return "";
    return buf;
}

// ---------------------------------------------------------------------------
// INI model: preserves Dolphin.ini structure exactly; edits keys in place
// ---------------------------------------------------------------------------
enum class LineKind
{
    Preamble,
    Section,
    Key,
    Raw,
};

struct IniLine
{
    LineKind kind;
    std::string name;
    std::string raw;
};

static bool g_ini_trailing_nl = true;

static std::vector<IniLine> ini_parse(const std::string& text)
{
    g_ini_trailing_nl = (!text.empty() && text.back() == '\n');
    std::vector<IniLine> lines;
    size_t i = 0;
    bool in_section = false;
    while (i < text.size())
    {
        size_t nl = text.find('\n', i);
        std::string line = text.substr(i, nl == std::string::npos ? std::string::npos : nl - i);
        i = (nl == std::string::npos) ? text.size() : nl + 1;

        std::string t = trim(line);
        if (t.empty() || t[0] == ';' || t[0] == '#')
        {
            lines.push_back({in_section ? LineKind::Raw : LineKind::Preamble, "", line});
            continue;
        }
        if (t[0] == '[')
        {
            size_t e = t.find(']');
            std::string name = trim(t.substr(1, e == std::string::npos ? std::string::npos : e - 1));
            lines.push_back({LineKind::Section, name, line});
            in_section = true;
        }
        else if (t.find('=') != std::string::npos)
        {
            size_t p = t.find('=');
            lines.push_back({LineKind::Key, trim(t.substr(0, p)), line});
        }
        else
        {
            lines.push_back({LineKind::Raw, "", line});
        }
    }
    return lines;
}

static std::string ini_serialize(const std::vector<IniLine>& lines)
{
    std::string out;
    for (const auto& l : lines)
    {
        out += l.raw;
        out += "\n";
    }
    if (!g_ini_trailing_nl && !lines.empty() && !out.empty())
        out.pop_back();
    return out;
}

static bool ini_set(std::vector<IniLine>& L, const std::string& section, const std::string& key, const std::string& value)
{
    int sec_start = -1;
    for (size_t i = 0; i < L.size(); i++)
        if (L[i].kind == LineKind::Section && L[i].name == section)
        {
            sec_start = static_cast<int>(i);
            break;
        }
    if (sec_start < 0)
    {
        L.push_back({LineKind::Section, section, "[" + section + "]"});
        L.push_back({LineKind::Key, key, key + " = " + value});
        return true;
    }
    int sec_end = sec_start + 1;
    for (int i = sec_start + 1; i < static_cast<int>(L.size()); i++)
    {
        if (L[i].kind == LineKind::Section)
            break;
        sec_end = i + 1;
    }
    for (int i = sec_start + 1; i < sec_end; i++)
        if (L[i].kind == LineKind::Key && L[i].name == key)
        {
            L[i].raw = key + " = " + value;
            return true;
        }
    L.insert(L.begin() + sec_end, {LineKind::Key, key, key + " = " + value});
    return true;
}

// ---------------------------------------------------------------------------
// state (JSON, hand-rolled; our format only)
// ---------------------------------------------------------------------------
struct State
{
    std::string profile;
    std::string device;
    std::string devpath;
    std::string uniq;
    int sdl_index = -1;
    std::map<int, int> managed; // SI port -> last value written
    long long ts = 0;

    static State load(const std::string& path)
    {
        State s;
        std::string text;
        if (!read_file(path, text))
            return s;
        auto grab_str = [&](const char* key) -> std::string {
            std::string needle = std::string("\"") + key + "\":\"";
            size_t a = text.find(needle);
            if (a == std::string::npos)
                return "";
            a += needle.size();
            size_t b = text.find('"', a);
            if (b == std::string::npos)
                return "";
            return text.substr(a, b - a);
        };
        auto grab_int = [&](const char* key, long long def) -> long long {
            std::string needle = std::string("\"") + key + "\":";
            size_t a = text.find(needle);
            if (a == std::string::npos)
                return def;
            a += needle.size();
            while (a < text.size() && text[a] == ' ')
                a++;
            return strtoll(text.c_str() + a, nullptr, 10);
        };
        s.profile = grab_str("profile");
        s.device = grab_str("device");
        s.devpath = grab_str("devpath");
        s.uniq = grab_str("uniq");
        s.sdl_index = static_cast<int>(grab_int("sdl_index", -1));
        s.ts = grab_int("ts", 0);
        size_t ma = text.find("\"managed\":{");
        if (ma != std::string::npos)
        {
            ma += strlen("\"managed\":{");
            size_t mb = text.find('}', ma);
            if (mb != std::string::npos)
            {
                std::string obj = text.substr(ma, mb - ma);
                size_t i = 0;
                while (i < obj.size())
                {
                    // expect '"port":value[,]'
                    size_t q1 = obj.find('"', i);
                    if (q1 == std::string::npos)
                        break;
                    size_t q2 = obj.find('"', q1 + 1);
                    if (q2 == std::string::npos)
                        break;
                    std::string port_s = obj.substr(q1 + 1, q2 - q1 - 1);
                    size_t c1 = obj.find(':', q2 + 1);
                    if (c1 == std::string::npos)
                        break;
                    size_t comma = obj.find(',', c1);
                    size_t end = comma;
                    if (end == std::string::npos || end > mb)
                        end = obj.size();
                    std::string v = trim(obj.substr(c1 + 1, end - c1 - 1));
                    if (!v.empty() && v.find_first_not_of("0123456789-") == std::string::npos)
                        s.managed[std::atoi(port_s.c_str())] = std::atoi(v.c_str());
                    i = end;
                    if (i < obj.size() && obj[i] == ',')
                        i++;
                    else
                        break;
                }
            }
        }
        return s;
    }

    bool save(const std::string& path, const std::string& rundir) const
    {
        std::string json = "{\"profile\":\"" + profile + "\",\"device\":\"" + device +
                           "\",\"devpath\":\"" + devpath + "\",\"uniq\":\"" + uniq +
                           "\",\"sdl_index\":" + std::to_string(sdl_index) + ",\"managed\":{";
        bool first = true;
        for (const auto& [port, val] : managed)
        {
            if (!first)
                json += ",";
            first = false;
            json += "\"" + std::to_string(port) + "\":" + std::to_string(val);
        }
        json += "},\"ts\":" + std::to_string(ts) + "}\n";
        uid_t u;
        gid_t g;
        choose_owner(rundir, path, u, g);
        return write_atomic(path, json, u, g, 0644);
    }
};

static std::string state_path(const Cfg& cfg)
{
    return cfg.rundir + "/state.json";
}

// ---------------------------------------------------------------------------
// identity resolution from sysfs
// ---------------------------------------------------------------------------
struct Identity
{
    std::string devname;
    std::string name;
    std::string vendor;
    std::string product;
    std::string uniq; // input device uniq — dedupe event9 + js1 nodes of one device
    std::string devpath; // /devices/... sysfs path (realpath minus "/sys")
    int sdl_index = -1;
    std::string profile;
    bool is_gamepad = false;
};

static Identity resolve_device(const std::string& devname, bool verbose = false)
{
    Identity id;
    id.devname = devname;
    std::string base = trim(devname);
    size_t sl = base.find_last_of('/');
    if (sl != std::string::npos)
        base = base.substr(sl + 1);
    std::string syscls = "/sys/class/input/" + base;

    auto dbg = [&](const std::string& path, const std::string& v, bool ok) {
        if (verbose)
            fprintf(stderr, "  probe: %s -> %s [%s]\n", path.c_str(), ok ? v.substr(0, 48).c_str() : "<unreadable>", ok ? "ok" : "MISS");
    };

    std::string v;
    {
        bool ok = read_file(syscls + "/device/name", v);
        if (ok)
            id.name = trim(v);
        dbg(syscls + "/device/name", v, ok);
    }
    {
        bool ok = read_file(syscls + "/device/id/vendor", v);
        if (ok)
            id.vendor = trim(v);
        dbg(syscls + "/device/id/vendor", v, ok);
    }
    {
        bool ok = read_file(syscls + "/device/id/product", v);
        if (ok)
            id.product = trim(v);
        dbg(syscls + "/device/id/product", v, ok);
    }

    bool has_abs = false, has_key_ev = false, has_game_button = false, have_key_mask = false;
    {
        // Newer kernels: <device>/capabilities/ev is a hex bitmask of EV types.
        // (EV_SYN=0, EV_KEY=1, EV_ABS=3). Older kernels: <syscls>/capabilities
        // file with a decimal list — kept as fallback.
        std::string hex;
        if (read_file(syscls + "/device/capabilities/ev", hex))
        {
            std::string h = trim(hex);
            unsigned long long bits = 0;
            size_t i = 0;
            while (i < h.size())
            {
                while (i < h.size() && (h[i] == ' ' || h[i] == '\n' || h[i] == '\r' || h[i] == '\t'))
                    i++;
                size_t j = i;
                while (j < h.size() && isxdigit(static_cast<unsigned char>(h[j])))
                    j++;
                if (i == j)
                    break;
                bits |= strtoull(h.substr(i, j - i).c_str(), nullptr, 16);
                i = j;
            }
            has_abs = (bits & (1ull << 3)) != 0;
            has_key_ev = (bits & (1ull << 1)) != 0;
        }
        else if (read_file(syscls + "/capabilities", v))
        {
            size_t i = 0;
            while (i < v.size())
            {
                while (i < v.size() && (v[i] == ' ' || v[i] == '\n' || v[i] == '\r' || v[i] == '\t'))
                    i++;
                size_t j = i;
                while (j < v.size() && isdigit(static_cast<unsigned char>(v[j])))
                    j++;
                if (i == j)
                    break;
                int cap = std::atoi(v.substr(i, j - i).c_str());
                if (cap == 3)
                    has_abs = true;
                if (cap == 1)
                    has_key_ev = true;
                i = j;
            }
        }
    }
    {
        // Gamepad-vs-mouse/keyboard discriminator: the key bitmask must
        // contain a game button. Standard pads use BTN_A..BTN_THUMB (30..52)
        // plus BTN_BASE..BTN_DPAD (299..312); Wolf's synthesized virtual
        // pads (uinput) map their buttons into the KEY 48..62 range — so the
        // window is 30..62 ∪ 299..312. Mice report BTN_LEFT/MIDDLE/RIGHT
        // (256..284) and keyboards lack EV_ABS, so both stay excluded.
        // Layout: <device>/capabilities/key = 64-bit hex words, word N =
        // bits 64N..64N+63, word 0 first.
        std::string k;
        if (read_file(syscls + "/device/capabilities/key", k))
        {
            have_key_mask = true;
            std::vector<unsigned long long> words(12, 0);
            std::string s = trim(k);
            size_t i = 0, wi = 0;
            while (i < s.size() && wi < 12)
            {
                while (i < s.size() && (s[i] == ' ' || s[i] == '\n' || s[i] == '\r' || s[i] == '\t'))
                    i++;
                size_t j = i;
                while (j < s.size() && isxdigit(static_cast<unsigned char>(s[j])))
                    j++;
                if (i == j)
                    break;
                words[wi++] = strtoull(s.substr(i, j - i).c_str(), nullptr, 16);
                i = j;
            }
            auto bit_set = [&](int bit) -> bool {
                int w = bit / 64;
                int off = bit % 64;
                return w < 12 && (words[w] & (1ull << off)) != 0;
            };
            if (verbose)
                fprintf(stderr, "  probe: key words: %016llx %016llx %016llx %016llx (parsed %zu)\n",
                        words[0], words[1], words[2], words[3], wi);
            for (int b = 30; b <= 62; ++b)
                if (bit_set(b))
                    has_game_button = true;
            for (int b = 299; b <= 312; ++b)
                if (bit_set(b))
                    has_game_button = true;
        }
    }
    id.is_gamepad = has_abs && has_key_ev && (has_game_button || !have_key_mask);
    if (verbose)
        fprintf(stderr, "  probe: has_abs=%d has_key_ev=%d has_game_button=%d have_key_mask=%d -> is_gamepad=%d\n",
                has_abs, has_key_ev, has_game_button, have_key_mask, id.is_gamepad);
    {
        std::string u;
        if (read_file(syscls + "/device/uniq", u))
            id.uniq = trim(u);
    }

    // SDL joystick index: js<N> whose sysfs input-device dir matches ours
    std::string ev_real = realpath_or_empty(syscls);
    if (!ev_real.empty() && ev_real.rfind("/sys", 0) == 0)
        id.devpath = ev_real.substr(4); // /sys/devices/... → /devices/...
    std::string ev_dir;
    if (!ev_real.empty())
    {
        size_t sl2 = ev_real.find_last_of('/');
        ev_dir = ev_real.substr(0, sl2 == std::string::npos ? 0 : sl2);
    }
    for (int n = 0; n < 32; n++)
    {
        std::string js = "/sys/class/input/js" + std::to_string(n);
        std::string js_real = realpath_or_empty(js);
        if (js_real.empty())
            continue;
        size_t sl3 = js_real.find_last_of('/');
        std::string js_dir = js_real.substr(0, sl3 == std::string::npos ? 0 : sl3);
        if (!ev_dir.empty() && js_dir == ev_dir)
        {
            id.sdl_index = n;
            break;
        }
    }

    auto lower = [](std::string s) {
        for (auto& c : s)
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        return s;
    };
    std::string ln = lower(id.name);
    if (id.vendor == "045e" || ln.find("xbox") != std::string::npos)
        id.profile = "xbox";
    else if (ln.find("dualsense") != std::string::npos || ln.find("playstation 5") != std::string::npos)
        id.profile = "dualsense";
    else if (ln.find("dualshock") != std::string::npos || id.vendor == "054c" || ln.find("playstation") != std::string::npos)
        id.profile = "dualshock";
    else if (ln.find("gamecube") != std::string::npos)
        id.profile = "gamecube";
    else if (id.is_gamepad)
        id.profile = "gamepad";
    else
        id.profile = "other";
    return id;
}

static std::vector<Identity> scan_gamepads()
{
    std::vector<Identity> out;
    DIR* d = ::opendir("/sys/class/input");
    if (!d)
        return out;
    struct dirent* e;
    std::vector<std::string> evs;
    while ((e = ::readdir(d)) != nullptr)
    {
        if (strncmp(e->d_name, "event", 5) == 0)
            evs.push_back(e->d_name);
    }
    ::closedir(d);
    std::set<std::string> seen_uniq;
    for (const auto& ev : evs)
    {
        Identity id = resolve_device("/dev/input/" + ev);
        if (!id.is_gamepad)
            continue;
        // One input device surfaces as several nodes (event9 + js1):
        // dedupe by the input device's uniq, keep the first node.
        const std::string key = id.uniq.empty() ? "/dev/input/" + ev : id.uniq;
        if (!seen_uniq.insert(key).second)
            continue;
        out.push_back(std::move(id));
    }
    return out;
}

// ---------------------------------------------------------------------------
// netlink: receive udev hotplug events (group 2), send synthetic ones
// ---------------------------------------------------------------------------
static const int NL_GROUP_UDEV = 2;

struct Uevent
{
    std::string action;
    std::string devname;
    std::string devpath;
};

// payload (after nlmsghdr + 16-byte uevent header): NUL-terminated "KEY=VALUE" pairs
static std::vector<Uevent> parse_ueline(const unsigned char* payload, size_t len)
{
    std::vector<Uevent> events;
    if (len < 2)
        return events;
    std::map<std::string, std::string> kv;
    size_t i = 0;
    while (i < len)
    {
        size_t nl = len;
        for (size_t k = i; k < len; k++)
            if (payload[k] == 0)
            {
                nl = k;
                break;
            }
        std::string tok(reinterpret_cast<const char*>(payload + i), nl - i);
        size_t eq = tok.find('=');
        if (eq != std::string::npos)
            kv[tok.substr(0, eq)] = tok.substr(eq + 1);
        i = (nl < len) ? nl + 1 : len;
    }
    auto it_sub = kv.find("SUBSYSTEM");
    auto it_act = kv.find("ACTION");
    auto it_dev = kv.find("DEVNAME");
    if (it_sub != kv.end() && it_sub->second == "input" && it_act != kv.end() && it_dev != kv.end())
    {
        const std::string& a = it_act->second;
        if (a == "add" || a == "remove" || a == "change")
        {
            Uevent u;
            u.action = a;
            u.devname = it_dev->second;
            auto it_dp = kv.find("DEVPATH");
            if (it_dp != kv.end())
                u.devpath = it_dp->second;
            events.push_back(std::move(u));
        }
    }
    return events;
}

static int nl_open_recv()
{
    int fd = ::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    if (fd < 0)
    {
        logf("socket(NETLINK_KOBJECT_UEVENT): %s", strerror(errno));
        return -1;
    }
    struct sockaddr_nl s;
    memset(&s, 0, sizeof(s));
    s.nl_family = AF_NETLINK;
    s.nl_pid = 0;
    if (::bind(fd, reinterpret_cast<struct sockaddr*>(&s), sizeof(s)) != 0)
    {
        logf("bind: %s", strerror(errno));
        ::close(fd);
        return -1;
    }
    int grp = NL_GROUP_UDEV;
    if (::setsockopt(fd, SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, &grp, sizeof(grp)) != 0)
    {
        logf("join group %d: %s", NL_GROUP_UDEV, strerror(errno));
        ::close(fd);
        return -1;
    }
    return fd;
}

static bool nl_recv(int fd, std::vector<Uevent>& events)
{
    struct pollfd p;
    p.fd = fd;
    p.events = POLLIN;
    p.revents = 0;
    int pr = ::poll(&p, 1, 200);
    if (pr < 0)
    {
        if (errno == EINTR)
            return false;
        logf("poll: %s", strerror(errno));
        return false;
    }
    if (pr == 0)
        return false;

    std::vector<unsigned char> buf(262144);
    ssize_t n = ::recv(fd, buf.data(), buf.size(), 0);
    if (n <= 0)
        return false;
    size_t off = 0;
    while (off + NLMSG_HDRLEN <= static_cast<size_t>(n))
    {
        struct nlmsghdr* h = reinterpret_cast<struct nlmsghdr*>(buf.data() + off);
        if (h->nlmsg_len < NLMSG_HDRLEN)
            break;
        size_t payload_off = NLMSG_HDRLEN + 16; // skip uevent {seq,sec,usec,cpu} header
        if (h->nlmsg_len >= payload_off)
        {
            auto evs = parse_ueline(buf.data() + off + payload_off, h->nlmsg_len - payload_off);
            events.insert(events.end(), evs.begin(), evs.end());
        }
        off += NLMSG_ALIGN(h->nlmsg_len);
    }
    return !events.empty();
}

// Emit a synthetic uevent exactly the way fake-udev does: one netlink message
// to the udev multicast group (group 2) with a 16-byte udev header + payload.
static bool nl_send_event(const std::string& action, const std::string& devname, const std::string& devpath)
{
    std::string payload;
    payload += "ACTION=" + action + "\0";
    payload += "DEVNAME=" + devname + "\0";
    if (!devpath.empty())
        payload += "DEVPATH=" + devpath + "\0";
    payload += "SEQNUM=99999\0";
    payload += "SUBSYSTEM=input\0";
    payload += "ID_INPUT=1\0";
    payload += "ID_INPUT_JOYSTICK=1\0";

    std::vector<unsigned char> msg(NLMSG_HDRLEN + 16 + payload.size(), 0);
    struct nlmsghdr* h = reinterpret_cast<struct nlmsghdr*>(msg.data());
    h->nlmsg_len = static_cast<unsigned int>(msg.size());
    h->nlmsg_type = 0x8000; // NLMSG_MULTICAST — multicast send to the udev group
    h->nlmsg_flags = 0;
    h->nlmsg_seq = 0;
    h->nlmsg_pid = 0;
    uint32_t* uh = reinterpret_cast<uint32_t*>(msg.data() + NLMSG_HDRLEN);
    uh[0] = 1; // seq
    uh[1] = 0; // timestamp sec
    uh[2] = 0; // timestamp usec
    uh[3] = 0; // cpu
    memcpy(msg.data() + NLMSG_HDRLEN + 16, payload.data(), payload.size());

    int fd = ::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    if (fd < 0)
    {
        logf("socket: %s", strerror(errno));
        return false;
    }
    struct sockaddr_nl s;
    memset(&s, 0, sizeof(s));
    s.nl_family = AF_NETLINK;
    s.nl_pid = 0;
    if (::bind(fd, reinterpret_cast<struct sockaddr*>(&s), sizeof(s)) != 0)
    {
        logf("bind: %s", strerror(errno));
        ::close(fd);
        return false;
    }
    int grp = NL_GROUP_UDEV;
    // Multicast send on this kernel: join the group, then send() with
    // nlmsg_type = NLMSG_MULTICAST — connect(group) is rejected with EPERM.
    if (::setsockopt(fd, SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, &grp, sizeof(grp)) != 0)
    {
        logf("join group %d: %s", NL_GROUP_UDEV, strerror(errno));
        ::close(fd);
        return false;
    }
    size_t off = 0;
    bool ok = true;
    while (off < msg.size())
    {
        ssize_t sn = ::send(fd, msg.data() + off, msg.size() - off, 0);
        if (sn < 0)
        {
            if (errno == EINTR)
                continue;
            logf("send: %s", strerror(errno));
            ok = false;
            break;
        }
        off += static_cast<size_t>(sn);
    }
    ::close(fd);
    return ok;
}

// ---------------------------------------------------------------------------
// adapters
// ---------------------------------------------------------------------------
// Dolphin 25.x+ (2609a): per-port controller config is entirely [Core]
// SIDevice0..3 in <home>/.config/dolphin-emu/Dolphin.ini — the SI device TYPE
// per port (SerialInterface::SIDevices). Physical devices are auto-associated
// by Dolphin's ControllerInterface; there is no device-binding key.
static const int SI_NONE = 0;
static const int SI_GC_CONTROLLER = 6;

static bool apply_dolphin(const Cfg& cfg, const std::optional<Identity>& pad, State& st)
{
    std::string path = cfg.home + "/.config/dolphin-emu/Dolphin.ini";
    std::string text;
    bool existed = read_file(path, text);
    auto lines = ini_parse(text);

    int val = pad ? SI_GC_CONTROLLER : SI_NONE;
    for (int p : cfg.ports)
    {
        std::string key = "SIDevice" + std::to_string(p);
        ini_set(lines, "Core", key, std::to_string(val));
        st.managed[p] = val;
    }

    if (!mkdir_p(dirname_of(path)))
        return false;
    uid_t u;
    gid_t g;
    choose_owner(cfg.home, path, u, g);
    bool ok = write_atomic(path, ini_serialize(lines), u, g);
    logf("dolphin: %s -> %s (%s)", path.c_str(), ok ? "updated" : "FAILED", existed ? "modified" : "created");
    return ok;
}

// v1: only Dolphin is implemented; the rest land in M4 (templates + verify
// when the emulators land in the image).
static void apply_all(const Cfg& cfg, const std::optional<Identity>& pad, State& st)
{
    apply_dolphin(cfg, pad, st);
    for (const char* name : {"pcsx2", "rpcs3", "yuzu", "ppsspp"})
        logf("%s: adapter not implemented yet (M4) — skipped", name);
    st.ts = time(nullptr);
    st.save(state_path(cfg), cfg.rundir);
}

static void handle_add(const Cfg& cfg, State& st, const Identity& id, const std::string& uevent_devpath = "")
{
    st.profile = id.profile;
    st.device = id.devname;
    st.devpath = uevent_devpath.empty() ? id.devpath : uevent_devpath;
    st.uniq = id.uniq;
    st.sdl_index = id.sdl_index;
    logf("controller connected: %s (%s, vendor %s:%s, sdl index %d)",
         id.name.empty() ? "?" : id.name.c_str(), id.devname.c_str(), id.vendor.c_str(), id.product.c_str(), id.sdl_index);
    apply_all(cfg, id, st);
}

static void handle_remove(const Cfg& cfg, State& st, const std::string& devname)
{
    if (!st.device.empty())
        logf("controller disconnected: %s", devname.c_str());
    st.profile = "";
    st.device = "";
    st.devpath = "";
    st.uniq = "";
    st.sdl_index = -1;
    apply_all(cfg, std::nullopt, st);
}

// One physical input device can surface as several nodes (event9 + js1) and
// arrive as separate uevents; match by the input-device prefix of the
// devpaths so a remove on any node clears the state.
static bool same_input_device(const State& st, const std::string& devname, const std::string& devpath)
{
    if (st.device == devname)
        return true;
    auto prefix = [](const std::string& dp) -> std::string {
        size_t i = dp.find("/event");
        if (i == std::string::npos)
            i = dp.find("/js");
        if (i == std::string::npos)
            return "";
        return dp.substr(0, i);
    };
    std::string sp = prefix(st.devpath);
    std::string up = prefix(devpath);
    return !sp.empty() && sp == up;
}

// ---------------------------------------------------------------------------
// daemon
// ---------------------------------------------------------------------------
static std::atomic<bool> g_running{true};

static void on_sig(int)
{
    g_running = false;
}

static void daemon_main(const Cfg& cfg)
{
    ::signal(SIGTERM, on_sig);
    ::signal(SIGINT, on_sig);
    if (!mkdir_p(cfg.rundir))
        return;

    State st = State::load(state_path(cfg));
    bool fresh = st.device.empty() && st.managed.empty();

    // Initial scan (record only). If a pad is already present on a fresh
    // start, apply it — covers the case where the daemon starts before the
    // one-shot prelaunch apply.
    auto scan = scan_gamepads();
    if (scan.size() >= 1)
    {
        auto id = scan[0];
        st.profile = id.profile;
        st.device = id.devname;
        st.sdl_index = id.sdl_index;
        if (fresh)
        {
            logf("startup: controller detected: %s (%s)", id.name.c_str(), id.devname.c_str());
            apply_all(cfg, id, st);
        }
        else
            logf("startup: controller present: %s (%s)", id.name.c_str(), id.devname.c_str());
    }
    else
    {
        logf("startup: no controller present");
    }

    int fd = nl_open_recv();
    if (fd >= 0)
        logf("listening for udev hotplug events (netlink group %d)", NL_GROUP_UDEV);
    else
        logf("WARNING: netlink unavailable — falling back to sysfs rescan only");

    time_t last_rescan = time(nullptr);
    {
        // pid file for the prelaunch script / ops
        std::string pidfile = cfg.rundir + "/pid";
        int pfd = ::open(pidfile.c_str(), O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0644);
        if (pfd >= 0)
        {
            std::string s = std::to_string(getpid());
            (void)::write(pfd, s.c_str(), s.size());
            ::close(pfd);
        }
    }
    while (g_running)
    {
        std::vector<Uevent> evs;
        if (fd >= 0)
            nl_recv(fd, evs); // poll times out every ~200ms — keep looping, rescan below
        else
            ::sleep(1);
        for (const auto& u : evs)
        {
            logf("uevent: %s %s", u.action.c_str(), u.devname.c_str());
            if (u.action == "remove")
            {
                if (!st.device.empty() && same_input_device(st, u.devname, u.devpath))
                    handle_remove(cfg, st, u.devname);
            }
            else
            {
                Identity id = resolve_device(u.devname);
                if (id.is_gamepad)
                    handle_add(cfg, st, id, u.devpath);
            }
        }
        // periodic rescan: netlink is not replayed; catch missed events and
        // device state we missed (must run even on poll timeouts)
        time_t now = time(nullptr);
        if (now - last_rescan >= 3)
        {
            last_rescan = now;
            auto cur = scan_gamepads();
            if (st.device.empty())
            {
                if (cur.size() >= 1)
                    handle_add(cfg, st, cur[0]);
            }
            else
            {
                bool still = false;
                for (const auto& c : cur)
                {
                    if (c.devname == st.device)
                        still = true;
                    if (!st.uniq.empty() && c.uniq == st.uniq)
                        still = true;
                }
                if (!still)
                    handle_remove(cfg, st, st.device);
            }
        }
    }
    ::unlink((cfg.rundir + "/pid").c_str());
    logf("daemon stopped");
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
static void do_apply(const Cfg& cfg)
{
    auto scan = scan_gamepads();
    State st = State::load(state_path(cfg));
    std::optional<Identity> pad;
    if (scan.size() == 1)
        pad = scan[0];
    else if (scan.size() > 1)
    {
        for (const auto& c : scan)
            if (st.device == c.devname)
                pad = c;
        if (!pad)
        {
            pad = scan[0];
            logf("WARNING: %d gamepads present — using %s", static_cast<int>(scan.size()), pad->devname.c_str());
        }
    }
    if (pad)
        logf("apply: controller %s (%s)", pad->name.c_str(), pad->devname.c_str());
    else
        logf("apply: no controller present");
    apply_all(cfg, pad, st);
}

static void do_status(const Cfg& cfg)
{
    State st = State::load(state_path(cfg));
    printf("state file:      %s\n", state_path(cfg).c_str());
    printf("controller:      %s\n", st.device.empty() ? "(none)" : st.device.c_str());
    printf("profile:         %s\n", st.profile.empty() ? "-" : st.profile.c_str());
    printf("sdl index:       %d\n", st.sdl_index);
    printf("managed ports:   ");
    if (st.managed.empty())
        printf("(none)\n");
    else
    {
        for (const auto& [port, val] : st.managed)
            printf("P%d=%d ", port, val);
        printf("\n");
    }
    printf("current scan:    ");
    auto scan = scan_gamepads();
    if (scan.empty())
        printf("(no gamepads)\n");
    else
        for (const auto& c : scan)
            printf("%s (%s %s:%s)\n  ", c.devname.c_str(), c.profile.c_str(), c.vendor.c_str(), c.product.c_str());
    if (!scan.empty())
        printf("\n");
}

static bool do_selftest(const Cfg& cfg, bool plug)
{
    (void)cfg;
    bool ok = nl_send_event(plug ? "add" : "remove", "/dev/input/event9", "/devices/virtual/input/input88/event9");
    logf("selftest: sent %s for /dev/input/event9 (%s)", plug ? "add" : "remove", ok ? "ok" : "FAILED");
    return ok;
}

static void usage()
{
    fprintf(stderr,
            "hotplug-emu — udev hotplug → emulator controller config bridge\n"
            "usage: hotplug-emu <mode> [options]\n"
            "  daemon               run the listener daemon\n"
            "  apply [--all]       one-shot apply of current controller state\n"
            "  status               show detected controller + applied state\n"
            "  selftest-plug       emit synthetic add uevent (testing)\n"
            "  selftest-unplug     emit synthetic remove uevent (testing)\n");
}

int main(int argc, char** argv)
{
    if (argc < 2)
    {
        usage();
        return 2;
    }
    Cfg cfg = Cfg::load();
    std::string mode = argv[1];
    if (mode == "daemon")
    {
        daemon_main(cfg);
        return 0;
    }
    if (mode == "apply")
    {
        // --all / --emu dolphin are accepted (v1: dolphin only)
        do_apply(cfg);
        return 0;
    }
    if (mode == "status")
    {
        do_status(cfg);
        return 0;
    }
    if (mode == "probe")
    {
        if (argc < 3)
        {
            fprintf(stderr, "usage: hotplug-emu probe <devname>\n");
            return 2;
        }
        Identity id = resolve_device(argv[2], true);
        fprintf(stderr, "  probe: devname=%s name=%s vendor=%s product=%s uniq=%s sdl_index=%d profile=%s\n",
                id.devname.c_str(), id.name.c_str(), id.vendor.c_str(), id.product.c_str(), id.uniq.c_str(), id.sdl_index, id.profile.c_str());
        return 0;
    }
    if (mode == "selftest-plug")
        return do_selftest(cfg, true) ? 0 : 1;
    if (mode == "selftest-unplug")
        return do_selftest(cfg, false) ? 0 : 1;
    if (mode == "help" || mode == "--help" || mode == "-h")
    {
        usage();
        return 0;
    }
    fprintf(stderr, "hotplug-emu: unknown mode '%s'\n", mode.c_str());
    usage();
    return 2;
}
