#!/bin/sh

# Function to start remote process
start_remote_proc() {
    echo "Starting remote process..."
  # ADD REMOTEPROC
  if [ -d /sys/class/remoteproc/remoteproc0 ]; then
      if [ -f /lib/firmware/firmware ]; then
          echo "Boot CM4 firmware by remoteproc"
          echo firmware > /sys/class/remoteproc/remoteproc0/firmware
          echo start > /sys/class/remoteproc/remoteproc0/state
      fi
  fi
}

# Main script execution
start_remote_proc

# set tty h=40 w=140
stty rows 30 cols 80

umount -l /rom

rm -rf /overlay /rom

find / \
  -path /proc -prune -o \
  -path /sys -prune -o \
  -path /run -prune -o \
  -exec chown -R root:root {} \;

chown -R root:root /lib
chown -R root:root /lib64
chown -R root:root /bin

if [ -f "/linuxrc" ]; then
  chown root:root /linuxrc
fi

echo "Initialization tasks completed."
