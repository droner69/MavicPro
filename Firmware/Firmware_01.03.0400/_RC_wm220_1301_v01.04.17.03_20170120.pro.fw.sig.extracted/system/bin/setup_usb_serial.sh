#! /system/bin/sh

sn=$1

echo 0 > /sys/class/android_usb/android0/enable

if [ "$sn" == "" ]; then
	cmdline=`cat /proc/cmdline`
	grep production /proc/cmdline >> /dev/null
	if [ $? != 0 ];then
		# engineering version, use chip SN as adb device ID
		temp=${cmdline##*chip_sn=}
		sn=${temp%% *}
	else
		# production version, use board SN as adb device ID\
		temp=${cmdline##*board_sn=}
		sn=${temp%% *}
	fi
fi
busybox printf "$sn" > /sys/class/android_usb/android0/iSerial

echo 1 > /sys/class/android_usb/android0/enable

echo $sn > /data/dji/cfg/adb_serial

sleep 3
ifconfig rndis0 192.168.42.2
