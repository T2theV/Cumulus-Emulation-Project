#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/netlink.h>

int main()
{
    struct sockaddr_nl s;
    int fd, grp = 2;

    // A: no bind, no join, connect(group)
    fd = socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_groups = 2;
    printf("A (no bind, no join): connect -> %s\n", connect(fd, (struct sockaddr*)&s, sizeof(s)) < 0 ? strerror(errno) : "OK");
    close(fd);

    // B: bind(0), no join, connect(group)
    fd = socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_pid = 0;
    bind(fd, (struct sockaddr*)&s, sizeof(s));
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_groups = 2;
    printf("B (bind, no join):     connect -> %s\n", connect(fd, (struct sockaddr*)&s, sizeof(s)) < 0 ? strerror(errno) : "OK");
    close(fd);

    // C: bind(0), join(group), connect(group)
    fd = socket(AF_NETLINK, SOCK_RAW | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_pid = 0;
    bind(fd, (struct sockaddr*)&s, sizeof(s));
    printf("C: join -> %s\n", setsockopt(fd, SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, &grp, sizeof(grp)) < 0 ? strerror(errno) : "OK");
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_groups = 2;
    printf("C (bind, join):        connect -> %s\n", connect(fd, (struct sockaddr*)&s, sizeof(s)) < 0 ? strerror(errno) : "OK");
    char msg[16] = "test-payload";
    printf("C: send -> %s\n", send(fd, msg, sizeof(msg), 0) < 0 ? strerror(errno) : "OK");
    close(fd);

    // D: SOCK_DGRAM variant of C
    fd = socket(AF_NETLINK, SOCK_DGRAM | SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT);
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_pid = 0;
    bind(fd, (struct sockaddr*)&s, sizeof(s));
    printf("D: join -> %s\n", setsockopt(fd, SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, &grp, sizeof(grp)) < 0 ? strerror(errno) : "OK");
    memset(&s, 0, sizeof(s)); s.nl_family = AF_NETLINK; s.nl_groups = 2;
    printf("D (DGRAM bind, join):  connect -> %s\n", connect(fd, (struct sockaddr*)&s, sizeof(s)) < 0 ? strerror(errno) : "OK");
    printf("D: send -> %s\n", send(fd, msg, sizeof(msg), 0) < 0 ? strerror(errno) : "OK");
    close(fd);
    return 0;
}
