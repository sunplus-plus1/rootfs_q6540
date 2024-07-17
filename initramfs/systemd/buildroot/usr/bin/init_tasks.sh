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

echo "Initialization tasks completed."