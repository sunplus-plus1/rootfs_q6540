#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/input.h>
#include <time.h>
#include <string.h>

#define KEY_ENTER       28
#define KEY_VOLUMEDOWN	114
#define KEY_VOLUMEUP    115
  
// Function to run the application after the specified time
void run_app(const char *app) {
    printf("Running app: %s\n", app);
    system(app);
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <device> <pass_sec> <app_to_run>\n", argv[0]);
        return 1;
    }

    const char *device = argv[1];
    int pass_sec = atoi(argv[2]);
    const char *app_to_run = argv[3];
    int fd;

    fd = open(device, O_RDONLY);
    if (fd < 0) {
        // perror("Failed to open device");
        return 0;
    }

    struct input_event ev;
    time_t key_press_time = 0;

    printf("Monitoring key events...\n");

    while (read(fd, &ev, sizeof(struct input_event)) > 0) {
        if (ev.type == EV_KEY) {
            if (ev.value == 1) { // Key press
                key_press_time = time(NULL);
                printf("Key %d pressed\n", ev.code);
            }
            else if (ev.value == 0 && ev.code==KEY_ENTER) { // Key release
                time_t duration = time(NULL) - key_press_time;
                printf("Key %d released after %ld seconds\n", ev.code, duration);

                if (duration >= pass_sec) {
                    run_app(app_to_run);
                }
            }
        }
    }

    close(fd);
    return 0;
}