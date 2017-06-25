#! /system/bin/sh

### BEGIN INFO
# Used to test WIFI antenna rssi
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

MOD_DIR=/system/lib/modules/ath6k
FW_DIR=/system/etc/firmware/ath6k/AR6004/hw3.0

# Switch antenna to WIFI
/system/bin/antenna_switch.sh WIFI
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

# Unload ath1021 driver modules
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

# Reload ath1021 driver modules with tx99 mode
insmod $MOD_DIR/compat.ko
insmod $MOD_DIR/cfg80211.ko
insmod $MOD_DIR/ath6kl_usb.ko testmode=1 ath6kl_p2p=0x0 debug_quirks=0x200 debug_mask=0x40c00
echo "Bring up wlan0 interface"
sleep 1
busybox ifconfig wlan0 up
busybox ifconfig wlan0 192.168.2.1
if [ $? != 0 ]
then
	exit 1
fi

# Get antenna rssi
#echo "Get antenna rssi"
#LOOPS=10
#CT=0
#ANT=1
#while [ $CT -lt $LOOPS ]
#do
#    CT=`busybox expr $CT + 1`
#    echo "Antenna $ANT"
#    athtestcmd -i wlan0 --rx promis --rxfreq 2412 --rxchain $ANT
#    sleep 1
#    athtestcmd -i wlan0 --rx report
#    ANT=`busybox expr $ANT + 1`
#    if [ $ANT -gt 2 ]
#    then
#        ANT=1
#    fi
#done
exit 0
