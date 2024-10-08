#!/bin/sh

#pre-->system suspend, post-->system resume
#GPIO57-->AP6256 BT_REG_ON: It needs to be set low to high after system suspend and before reload FW bin file.
#                           bluetooth.service will call hciuart.service to reload FW bin file. 
case $1 in
    pre)
        if [ -L /sys/class/bluetooth/hci0 ]; then
            rfkill block bluetooth
        fi
        ;;
    post)
        if [ -L /sys/class/bluetooth/hci0 ]; then
            echo 57 > /sys/class/gpio/export
            echo 0 > /sys/class/gpio/GPIO57/value
            sleep 0.1
            echo 1 > /sys/class/gpio/GPIO57/value
            sleep 0.2
            systemctl restart bluetooth.service
            sleep 0.5
            rfkill unblock bluetooth
            sleep 0.1
        fi
        ;;
esac

