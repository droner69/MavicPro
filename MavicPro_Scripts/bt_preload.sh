#!/bin/sh

if [ -e /etc/bluetooth/ ]; then
	#amba mac
	if [ -e /proc/ambarella/board_info ]; then
		btmac=`cat /proc/ambarella/board_info | grep wifi1_mac | awk '{print $2}'`
		if [ "${btmac}" != "00:00:00:00:00:00" ] &&  [ "${btmac}" != "" ]; then
			echo -n ${btmac} > /tmp/wifi1_mac
		elif [ -e /etc/init.d/S51hibernation ]; then
			printf "%02X:%02X:%02X:%02X:%02X:%02X" $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256))  > /tmp/wifi1_mac
		fi
	fi
	cp -a /etc/bluetooth /tmp/
	cp /usr/local/share/script/hidraw0.sh /tmp/
fi
