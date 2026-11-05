// uinput-pad — register a test gamepad via /dev/uinput (run on the GOW host).
//
// usage: uinput-pad <hold-seconds>
//
// Creates a uinput gamepad named "hotplug-emu Test Xbox Pad" (name contains
// "xbox" so hotplug-emu maps it to the xbox profile), holds it open, and
// removes it on SIGTERM/SIGINT or after hold seconds — closing the fd
// removes the uinput device from the kernel, which is what the periodic
// sysfs rescan in the container must notice.
#include <linux/input.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

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
    sigaction(SIGTERM, &sa, nullptr);
    sigaction(SIGINT, &sa, nullptr);

    int fd = ::open("/dev/uinput", O_WRONLY | O_CLOEXEC);
    if (fd < 0)
    {
        perror("open /dev/uinput");
        return 1;
    }

    if (::ioctl(fd, UI_SET_DEVNAME, "hotplug-emu Test Xbox Pad") < 0)
    {
        perror("UI_SET_DEVNAME");
        return 1;
    }
    int evs[] = {EV_SYN, EV_KEY, EV_ABS};
    for (size_t i = 0; i < sizeof(evs) / sizeof(evs[0]); ++i)
        if (::ioctl(fd, UI_SET_EVBIT, evs[i]) < 0)
        {
            perror("UI_SET_EVBIT");
            return 1;
        }
    int keys[] = {BTN_A, BTN_B, BTN_X, BTN_Y, BTN_BASE, BTN_DPAD, BTN_START, BTN_MODE, BTN_THUMBL, BTN_THUMBR};
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); ++i)
        if (::ioctl(fd, UI_SET_KEYBIT, keys[i]) < 0)
        {
            perror("UI_SET_KEYBIT");
            return 1;
        }
    int abses[] = {ABS_X, ABS_Y};
    for (size_t i = 0; i < sizeof(abses) / sizeof(abses[0]); ++i)
    {
        struct input_absinfo a;
        memset(&a, 0, sizeof(a));
        a.value = 0;
        a.min = 0;
        a.max = 32767;
        if (::ioctl(fd, UI_SET_ABSBIT, abses[i]) < 0)
        {
            perror("UI_SET_ABSBIT");
            return 1;
        }
        if (::ioctl(fd, UI_SET_ABSINFO, &a) < 0)
        {
            perror("UI_SET_ABSINFO");
            return 1;
        }
    }
    if (::ioctl(fd, UI_COMMIT, 0) < 0)
    {
        perror("UI_COMMIT");
        return 1;
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
