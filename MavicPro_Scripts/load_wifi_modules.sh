#! /system/bin/sh

### BEGIN INFO
# Used to load wifi driver modules
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

MOD_DIR=/system/lib/modules/ath6k
FW_DIR=/system/etc/firmware/ath6k/AR6004/hw3.0

# Kill wpa_supplicant
if [ `ps | grep -c wpa_supplicant` -gt 0 ]
then
	echo "kill process wpa_supplicant first"
	kill `ps | grep wpa_supplicant | busybox awk -F ' ' '{print $2}'`
fi

# Kill hostapd
if [ `ps | grep -c hostapd` -gt 0 ]
then
	echo "kill process hostapd first"
	kill `ps | grep hostapd | busybox awk -F ' ' '{print $2}'`
fi

# Remove ath1021 driver modules
if [ `lsmod | grep -c ath6kl_usb` -gt 0 ]
then
	rmmod ath6kl_usb
fi

if [ `lsmod | grep -c cfg80211` -gt 0 ]
then
	rmmod cfg80211
fi

if [ `lsmod | grep -c compat` -gt 0 ]
then
	rmmod compat
fi

# Load ath1021 driver modules
echo "Loading driver modules ..."
insmod $MOD_DIR/compat.ko
insmod $MOD_DIR/cfg80211.ko
insmod $MOD_DIR/ath6kl_usb.ko ath6kl_p2p=0x0 ath6kl_roam_mode=0x10 debug_quirks=0x200
sleep 1
echo "Bring down wlan0..."
busybox ifconfig wlan0 down

