#!/bin/sh

ACTION_TYPE=$1

echo "ACTION_TYPE:  $ACTION_TYPE"
case $ACTION_TYPE in
    ins | INS)
        echo "ins usb module"
	echo device > /proc/ambarella/usbphy0
	modprobe usbcore
	modprobe udc-core
	modprobe ambarella_udc
	modprobe libcomposite
	#modprobe g_serial
	modprobe g_ether
	ifconfig usb0 192.168.1.3
        ;;
    none | NONE)
        echo "remove usb module"
        rmmod ehci_hcd
        rmmod g_ether
        rmmod g_serial
        rmmod libcomposite
        rmmod ambarella_udc
        rmmod udc-core
        rmmod usbcore
        rmmod usb-common
        ;;
    *)
        echo "ACTION_TYPE should be INS/NONE"
        exit -1
        ;;
esac
