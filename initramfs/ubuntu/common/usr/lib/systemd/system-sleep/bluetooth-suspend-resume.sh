#!/bin/sh

BLUETOOTH0_LINK=/sys/class/bluetooth/hci0
BLUETOOTH_SERVICE=/etc/systemd/system/hciuart.service
#pre-->system suspend, post-->system resume
#In EV & IO board, GPIO57-->AP6256 BT_REG_ON: It needs to be set low to high after system suspend and before reload FW bin file.
#Set GPIO57 to be rfkill_bluetooth GPIO control source, then BT_REG_ON will be switched during "rfkill block bluetooth" and "rfkill unblock bluetooth".
#bluetooth.service will call hciuart.service to reload FW bin file.
case $1 in
    pre)
        if [ -L $BLUETOOTH0_LINK ]; then
            rfkill block bluetooth
        fi
        ;;
    post)
        if [ -L $BLUETOOTH0_LINK ] && [ -f $BLUETOOTH_SERVICE ]; then
            rfkill unblock bluetooth
            systemctl restart bluetooth.service
        elif [ -L $BLUETOOTH0_LINK ];then
            rfkill unblock bluetooth
        fi
        ;;
esac

