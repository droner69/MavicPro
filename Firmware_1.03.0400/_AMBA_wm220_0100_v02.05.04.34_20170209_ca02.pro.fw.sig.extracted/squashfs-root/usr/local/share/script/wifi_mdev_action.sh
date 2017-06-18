#!/bin/sh

# Input from /etc/mdev.conf: $ACTION $DEVPATH
#echo $@ > /tmp/mdv_action_log.txt

# Only handle USB WiFi
# ACTION:add SUBSYSTEM:net DEVNAME:(null)
# DEVPATH:/devices/platform/ambarella-ehci/usb1/1-1/1-1.3/1-1.3:1.0/net/wlan0

if [ -e /tmp/S52wifi_running ]; then
	exit 0
fi

# Prevent /usr/local/share/script/insert_usb_modules.sh to hook wifi_start.sh
if [ "`pidof wifi_start.sh`" != "" ]; then
	exit 0
fi

usb=`echo $2 | awk -F "/usb" '{print $2}'`
net=`echo $2 | awk -F "net/" '{print $2}'`
if [ "$1" == "add" ] && [ "$net" == "wlan0" ] && [ "${usb}" != "" ]; then
	/usr/local/share/script/wifi_start.sh
#else
#	Maybe need to stop wifi if conflicts to with other devices.
#	/usr/local/share/script/wifi_stop.sh
fi

