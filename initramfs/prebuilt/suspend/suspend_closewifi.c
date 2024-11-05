#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <string.h>

#define UEVENT_MSG_LEN 4096
#define WLAN0_STATE "/sys/class/net/wlan0/device/rfkill/rfkill1/state"

void suspend() {
	int status = system("ls -l " WLAN0_STATE " > /dev/null 2>&1");
	if(status == 0)
		system("echo 0 > " WLAN0_STATE "");
	
	system("echo mem > /sys/power/state");
}

void resume() {
	int status = system("ls -l " WLAN0_STATE " > /dev/null 2>&1");
	if(status == 0)
		system("echo 1 > " WLAN0_STATE "");
}

int main() {
    int sockfd;
    struct sockaddr_nl sa;
    char buf[UEVENT_MSG_LEN];

    if ((sockfd = socket(AF_NETLINK, SOCK_RAW, NETLINK_KOBJECT_UEVENT)) == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    sa.nl_pid = getpid();
    sa.nl_groups = 1; // listen to multicast group 1
    if (bind(sockfd, (struct sockaddr *)&sa, sizeof(sa)) == -1) {
        perror("bind");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    while (1) {
        ssize_t len = recv(sockfd, buf, sizeof(buf), 0);
        if (len == -1) {
            perror("recv");
            close(sockfd);
            exit(EXIT_FAILURE);
        }

        if (len >= UEVENT_MSG_LEN) {
            fprintf(stderr, "Buffer overflow\n");
            continue;
        }

        buf[len] = '\0';
        for (int i = 0; i < len; ++i) {
            if(buf[i] == '\0')
                buf[i] = '*';
        }

        if ((strstr(buf, "SUBSYSTEM=remoteproc")) && (strstr(buf, "DEVICE=wlan0")))
        {
            if (strstr(buf, "ACTION=offline")) {
                suspend();
            } else if (strstr(buf, "ACTION=online")) {
                resume();
            }
        }
    }

    close(sockfd);
    return 0;
}
