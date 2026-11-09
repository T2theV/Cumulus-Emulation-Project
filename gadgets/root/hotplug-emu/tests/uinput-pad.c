// uinput-pad — register a test gamepad via /dev/uinput (run where /dev/uinput
// exists, e.g. a privileged container or the GOW host).
//
// usage: uinput-pad <hold-seconds>
//
// Creates a uinput gamepad named "hotplug-emu Test Xbox Pad" (name contains
// "xbox" so hotplug-emu maps it to the xbox profile), holds it open, and
// removes it on SIGTERM/SIGINT or after hold seconds — closing the fd removes
// the uinput device from the kernel, which is what the periodic sysfs rescan
// in the container must notice.
//
// Uses the MODERN uinput ioctl API (UI_DEV_SETUP / UI_ABS_SETUP / UI_DEV_CREATE),
// which supersedes the old write()-based uinput_user_dev + UI_COMMIT method.
#include <linux/input.h>
#include <linux/uinput.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <fcntl.h>

static volatile sig_atomic_t s_stop = 0;
static void onsig(int sig)
{
    (void)sig;
    s_stop = 1;
}

int main(int argc, char** argv)
{
    long hold = argc > 1 ? atol(argv[1]) : 3600;
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = onsig;
    sigaction(SIGTERM, &sa, 0);
    sigaction(SIGINT, &sa, 0);

    int fd = ::open("/dev/uinput", O_WRONLY | O_CLOEXEC);
    if (fd < 0)
    {
        perror("open /dev/uinput");
        return 1;
    }

    // Modern API: UI_DEV_SETUP sets name + id (supersedes UI_SET_DEVNAME/UI_SET_ID).
    struct uinput_setup setup;
    memset(&setup, 0, sizeof(setup));
    setup.id.vendor = 0x045e; // Microsoft
    setup.id.product = 0x02ea; // Xbox One
    setup.id.version = 0x0100;
    snprintf(setup.name, sizeof(setup.name), "hotplug-emu Test Xbox Pad");
    setup.ff_effects_max = 0;
    if (::ioctl(fd, UI_DEV_SETUP, &setup) < 0)
    {
        perror("UI_DEV_SETUP");
        return 1;
    }

    int evs[] = {EV_SYN, EV_KEY, EV_ABS};
    for (size_t i = 0; i < sizeof(evs) / sizeof(evs[0]); ++i)
        if (::ioctl(fd, UI_SET_EVBIT, evs[i]) < 0)
        {
            perror("UI_SET_EVBIT");
            return 1;
        }

    // Buttons in the standard gamepad range (BTN_A=304..BTN_THUMBR=318) plus
    // BTN_BASE; hotplug-emu's gamepad window (299..312) catches BTN_A..BTN_L2.
    int keys[] = {BTN_A, BTN_B, BTN_X, BTN_Y, BTN_BASE, BTN_DPAD_UP,
                  BTN_START, BTN_MODE, BTN_THUMBL, BTN_THUMBR};
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); ++i)
        if (::ioctl(fd, UI_SET_KEYBIT, keys[i]) < 0)
        {
            perror("UI_SET_KEYBIT");
            return 1;
        }

    // Abs axes via UI_ABS_SETUP (supersedes UI_SET_ABSBIT + UI_SET_ABSINFO).
    int abses[] = {ABS_X, ABS_Y};
    for (size_t i = 0; i < sizeof(abses) / sizeof(abses[0]); ++i)
    {
        struct uinput_abs_setup abs;
        memset(&abs, 0, sizeof(abs));
        abs.code = abses[i];
        abs.absinfo.value = 0;
        abs.absinfo.minimum = 0;
        abs.absinfo.maximum = 32767;
        if (::ioctl(fd, UI_ABS_SETUP, &abs) < 0)
        {
            perror("UI_ABS_SETUP");
            return 1;
        }
    }

    if (::ioctl(fd, UI_DEV_CREATE) < 0)
    {
        perror("UI_DEV_CREATE");
        return 1;
    }
    fprintf(stderr, "uinput pad created (hold %lds, pid %d); closing fd removes it\n", hold, getpid());

    if (hold > 0)
    {
        long slept = 0;
        while (!s_stop && slept < hold)
        {
            sleep(1);
            slept++;
        }
    }
    ::close(fd); // removes the device from the kernel
    return 0;
}
