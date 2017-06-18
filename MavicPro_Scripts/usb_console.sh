#!/bin/sh -x
killall syslogd
echo device > /proc/ambarella/usbphy0
modprobe usbcore
modprobe ehci-hcd
modprobe ohci-hcd
modprobe udc-core
modprobe ambarella_udc
modprobe libcomposite
modprobe g_serial
/sbin/getty -n -L 115200 /dev/ttyGS0 &
klogd
syslogd -O /dev/ttyGS0
