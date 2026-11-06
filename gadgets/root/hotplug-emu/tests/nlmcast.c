// nlmcast — minimal NETLINK_KOBJECT_UEVENT multicast plumbing test.
//   nlmcast recv   join group 1, dump raw bytes for 6s
//   nlmcast send   sendto group 1 a test payload
// Build: g++ -std=c++17 -O2 -static -o nlmcast nlmcast.c
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <string>
#include <vector>
#include <linux/netlink.h>
#include <sys/socket.h>
#include <unistd.h>
#include <poll.h>
#include <time.h>

static const int GROUP = 1;

static int open_nl()
{
    int fd = ::socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    if (fd < 0) { perror("socket"); exit(1); }
    struct sockaddr_nl s{};
    s.nl_family = AF_NETLINK;
    s.nl_pid = 0;
    if (::bind(fd, (struct sockaddr*)&s, sizeof(s)) < 0) { perror("bind"); exit(1); }
    return fd;
}

int main(int argc, char** argv)
{
    if (argc < 2) { fprintf(stderr, "usage: nlmcast recv|send\n"); return 2; }
    if (std::string(argv[1]) == "recv")
    {
        int fd = open_nl();
        int grp = GROUP;
        if (::setsockopt(fd, SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, &grp, sizeof(grp)) < 0)
        {
            fprintf(stderr, "join group %d: %s\n", GROUP, strerror(errno));
            return 1;
        }
        fprintf(stderr, "nlmcast: joined group %d, listening 6s (pid=%d)\n", GROUP, getpid());
        time_t deadline = time(nullptr) + 6;
        while (time(nullptr) < deadline)
        {
            struct pollfd p{fd, POLLIN, 0};
            int pr = ::poll(&p, 1, 500);
            if (pr <= 0) continue;
            std::vector<unsigned char> buf(65536);
            ssize_t n = ::recv(fd, buf.data(), buf.size(), 0);
            if (n <= 0) continue;
            fprintf(stderr, "nlmcast: RECEIVED %zd bytes:\n", n);
            for (ssize_t i = 0; i < n; i += 16)
            {
                fprintf(stderr, "  %04zX: ", (size_t)i);
                for (size_t j = 0; j < 16 && i + j < n; j++)
                    fprintf(stderr, "%02x ", buf[i + j]);
                fprintf(stderr, " |");
                for (size_t j = 0; j < 16 && i + j < n; j++)
                {
                    unsigned char c = buf[i + j];
                    fprintf(stderr, "%c", (c >= 32 && c < 127) ? c : '.');
                }
                fprintf(stderr, "|\n");
            }
        }
        return 0;
    }
    if (std::string(argv[1]) == "send")
    {
        int fd = open_nl();
        // NB: append NUL separators as single chars (payload.push_back('\0')).
        // `payload += "...\\0"` would use strlen and drop the NUL.
        std::string payload;
        payload += "ACTION=add";
        payload.push_back('\0');
        payload += "DEVNAME=/dev/input/event9";
        payload.push_back('\0');
        payload += "DEVPATH=/devices/virtual/input/input88/event9";
        payload.push_back('\0');
        payload += "SUBSYSTEM=input";
        payload.push_back('\0');
        payload += "SEQNUM=1";
        payload.push_back('\0');
        std::vector<unsigned char> msg(NLMSG_HDRLEN + payload.size(), 0);
        struct nlmsghdr* h = (struct nlmsghdr*)msg.data();
        h->nlmsg_len = (unsigned)msg.size();
        h->nlmsg_type = 0x8000;
        h->nlmsg_flags = 0;
        h->nlmsg_seq = 0;
        h->nlmsg_pid = 0;
        memcpy(msg.data() + NLMSG_HDRLEN, payload.data(), payload.size());
        struct sockaddr_nl dest{};
        dest.nl_family = AF_NETLINK;
        dest.nl_pid = 0;
        dest.nl_groups = 1u << (GROUP - 1);
        ssize_t sn = ::sendto(fd, msg.data(), msg.size(), 0, (struct sockaddr*)&dest, sizeof(dest));
        if (sn < 0)
        {
            fprintf(stderr, "sendto(group %d): %s\n", GROUP, strerror(errno));
            return 1;
        }
        fprintf(stderr, "nlmcast: sent %zd bytes to group %d (pid=%d)\n", sn, GROUP, getpid());
        return 0;
    }
    fprintf(stderr, "unknown mode\n");
    return 2;
}
