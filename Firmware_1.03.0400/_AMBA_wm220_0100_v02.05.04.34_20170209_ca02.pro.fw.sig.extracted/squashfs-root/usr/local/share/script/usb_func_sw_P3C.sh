#!/bin/sh

ACTION_TYPE=$1

echo "ACTION_TYPE:  $ACTION_TYPE"
case $ACTION_TYPE in
    ins | INS)
        echo "ins usb module"
	echo host > /proc/ambarella/usbphy0
	modprobe usbcore
	modprobe ehci_hcd
	modprobe rndis_host
#ifconfig usb0 192.168.1.3 up
        ;;
    none | NONE)
        echo "remove usb module"
        rmmod rndis_host
        ;;
    *)
        echo "ACTION_TYPE should be INS/NONE"
        exit -1
        ;;
esac
