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

# Function to change NPU device attritute
change_NPU_attr() {
  if [ -e /dev/galcore ];then
    echo "Change NPU device "galcore" file attritute"
    chmod 666 /dev/galcore
  fi
}

# Script execution
start_remote_proc
change_NPU_attr

umount -l /rom
rm -rf /overlay /rom

echo "Initialization tasks completed."
