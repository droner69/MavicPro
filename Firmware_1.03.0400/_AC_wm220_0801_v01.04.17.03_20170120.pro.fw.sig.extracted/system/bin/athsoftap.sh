#! /system/bin/sh

### BEGIN INFO
# Used to start WIFI Soft AP function via Atheros
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

CONTROL_DIR=/data/misc/wifi
MOD_DIR=/system/lib/modules/ath6k
FW_DIR=/system/etc/firmware/ath6k/AR6004/hw3.0
CONF=$CONTROL_DIR/hostapd.conf
HOSTAPD_CMD=/system/bin/hostapd
DHCP_DIR=/data/misc/dhcp
CMDLINE=`cat /proc/cmdline`
TEMP=${CMDLINE##*chip_sn=}
CHIP_SN=${TEMP%% *}
SSID="Mavic-"${CHIP_SN}
PSK=12341234
DEF_COUNTRY_CODE=CN
DEF_REG_DOMAIN=0x809c
COUNTRY_CODE_FILE=/amt/country.txt
FACTORY_WIFI_CONF=/amt/wifi.config

if [ ! -d $CONTROL_DIR ]
then
	echo "directory $CONTROL_DIR doen not exist"
	exit 1
fi

if [ `ps | grep -c hostapd` -gt 0 ]
then
    echo "kill process hostapd first"
    kill -2 `ps | grep hostapd | busybox awk -F ' ' '{print $2}'`
fi

if [ `lsmod | grep -c ath6kl_usb` -gt 0 ]
then
	busybox ifconfig wlan0 down
	rmmod ath6kl_usb
fi

if [ `lsmod | grep -c cfg80211` -gt 0 ]
then
	busybox ifconfig wlan0 down
	rmmod cfg80211
fi

if [ `lsmod | grep -c compat` -gt 0 ]
then
	busybox ifconfig wlan0 down
	rmmod compat
fi

# WIFI MAC address
#if [ "$2" = "mac" ]
#then
#   echo -e -n "\x00\x31\x09\x03\x09\x13" > $FW_DIR/softmac.bin
#fi

# Country Code for 1021 driver insmod param
if [ "$2" == "reg_domain" -a ! -z "$3" ]
then
    echo "over ride regdomain: "$DEF_REG_DOMAIN "->" "$3"
    DEF_REG_DOMAIN=$3
fi

# alpha2 code for hostapd.conf
if [ "$4" == "alpha2" -a ! -z "$5" ]
then
    echo "over ride alpha2: "$DEF_COUNTRY_CODE "->" "$5"
    DEF_COUNTRY_CODE=$5
fi

# Load Atheros Driver
insmod $MOD_DIR/compat.ko
insmod $MOD_DIR/cfg80211.ko
insmod $MOD_DIR/ath6kl_usb.ko ath6kl_p2p=0x0 debug_quirks=0x8200 reg_domain=$DEF_REG_DOMAIN recovery_enable_mode=0x2 #debug_mask=0x402
sleep 3
busybox ifconfig wlan0 up
busybox ifconfig wlan0 192.168.2.1
if [ $? != 0 ]
then
	exit 1
fi
#mount debugfs
mount -t debugfs none /sys/kernel/debug
#disable ht40
echo 1 0 1 0 > /sys/kernel/debug/ieee80211/phy0/ath6kl/ht_cap_params
#set rts threshhold
iw phy phy0 set rts 512

chown wifi.wifi $CONTROL_DIR
chmod 770 $CONTROL_DIR

# Check ssid/psk set in factory
if [ -f "$FACTORY_WIFI_CONF" ]
then
    cat $FACTORY_WIFI_CONF | grep psk
    if [ $? == 0 ]
    then
        PSK=`cat /amt/wifi.config | grep psk | busybox awk -F '=' '{print $2}'`
    fi
    cat $FACTORY_WIFI_CONF | grep ssid
    if [ $? == 0 ]
    then
        SSID=`cat /amt/wifi.config | grep ssid | busybox awk -F '=' '{print $2}'`
    fi
    echo $PSK, $SSID
fi

if [ ! -f "$CONF" ]
then
# Generate hostapd.conf
#echo "update_config=1"                       >> $CONF
echo "Generate hostapd.conf"
echo "driver=nl80211"                         >> $CONF
echo "interface=wlan0"                        >> $CONF
echo "ctrl_interface=/data/misc/wifi/hostapd" >> $CONF
echo "ssid="${SSID}                           >> $CONF
echo "country_code="$DEF_COUNTRY_CODE         >> $CONF
echo "ieee80211n=1"                           >> $CONF
echo "max_num_sta=1"                          >> $CONF
echo "ap_max_inactivity=10"                   >> $CONF
case "$1" in
    5G)
    echo "hw_mode=a"                          >> $CONF
    echo "channel=157"                        >> $CONF
    ;;
    *)
    echo "hw_mode=g"                          >> $CONF
    echo "channel=11"                         >> $CONF
    ;;
esac
echo "ignore_broadcast_ssid=0"                >> $CONF
echo "wpa=2"                                  >> $CONF
echo "wpa_key_mgmt=WPA-PSK"                   >> $CONF
echo "wpa_pairwise=CCMP"                      >> $CONF
echo "wpa_passphrase="${PSK}                  >> $CONF
else
    OLD_COUNTRY_CODE=`cat /data/misc/wifi/hostapd.conf | grep country_code | busybox awk -F '=' '{print $2}'`
    if [ "$OLD_COUNTRY_CODE" != "$DEF_COUNTRY_CODE" ]
    then
        echo "override country code in hostapd.conf: "$OLD_COUNTRY_CODE "->" ${DEF_COUNTRY_CODE}
        line=`cat /data/misc/wifi/hostapd.conf | grep -n country_code | busybox awk -F ':' '{print $1}'`
        target_str="country_code="${DEF_COUNTRY_CODE}
        busybox sed -i "${line}s:.*:$target_str:g" /data/misc/wifi/hostapd.conf
    fi
fi
sync

chown wifi.wifi $CONF
chmod 666 $CONF

# Disable power save
iw dev wlan0 set power_save off
# MTU configuration
busybox ifconfig wlan0 mtu 1500
# Disable CP
#busybox devmem 0xA0899188 8 1
#Start Soft AP
#$HOSTAPD_CMD $CONF &

#dhcp server
if [ ! -d $DHCP_DIR ]
then
	mkdir -p $DHCP_DIR
fi
echo > /data/misc/dhcp/udhcpd.leases
udhcpd_name="udhcpd_wifi"
udhcpd_pid=`busybox ps -T | grep $udhcpd_name | busybox awk -F ' ' '{print $1}' | busybox sed -n '1,1p'`
if [ $? == 0 ]
then
    echo "kill udhcpd first: ""$udhcpd_pid"
    kill -2 $udhcpd_pid
fi
busybox udhcpd /etc/udhcpd_wifi.conf
# Unlink the unused PF_UNIX socket
rm /data/misc/wifi/sockets/*

exit 0
