#! /system/bin/sh

### BEGIN INFO
# Used to init WIFI STA
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

CONTROL_DIR=/data/misc/wifi
MOD_DIR=/system/lib/modules/ath6k
FW_DIR=/system/etc/firmware/ath6k/AR6004/hw3.0
CONF=$CONTROL_DIR/wpa_supplicant.conf
WPA_SUPP_CMD=/system/bin/wpa_supplicant
#generate mac address
CMDLINE=`cat /proc/cmdline`
TEMP=${CMDLINE##*chip_sn=}
chip_sn=${TEMP%% *}
mac2=${chip_sn:0:2}
mac3=${chip_sn:2:2}
mac4=${chip_sn:4:2}
mac5=${chip_sn:6:2}
#AMT file path
AMT_FILE=/amt/WIFI_nvram.txt

if [ ! -d $CONTROL_DIR ]
then
	echo "directory $CONTROL_DIR doen not exist"
	exit 1
fi

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

# WIFI MAC address
#if [ "$2" = "mac" ]
#then
#	echo -e -n "\x00\x31\x09\x03\x09\x13" > $FW_DIR/softmac.bin
#fi
chip_sn_len=`busybox expr length "${chip_sn}"`
#chip_sn validation check
if [ "$chip_sn" == "" -o ${chip_sn_len} -lt 8 ]
then
	echo "Failed to get chip_sn: "${chip_sn}"len: "${chip_sn_len}
	exit -1
fi
echo "Generating mac address..."
mount -o remount,rw /system
sleep 1
WIFI_NVRAM_SIZE=0
if [ -f "$AMT_FILE" ]
then
   WIFI_NVRAM_SIZE=`busybox wc -c < $AMT_FILE`
   if [ $WIFI_NVRAM_SIZE == 6 ]
   then
       cp $AMT_FILE $FW_DIR/softmac.bin
   else
       echo -e -n "\x00\x31""\x${mac2}""\x${mac3}""\x${mac4}""\x${mac5}" > $FW_DIR/softmac.bin
   fi
else
    echo -e -n "\x00\x31""\x${mac2}""\x${mac3}""\x${mac4}""\x${mac5}" > $FW_DIR/softmac.bin
fi
sync
mount -o remount,ro /system

# Load ath1021 driver modules
echo "Loading driver modules ..."
insmod $MOD_DIR/compat.ko
insmod $MOD_DIR/cfg80211.ko
iw reg set US # Country code
insmod $MOD_DIR/ath6kl_usb.ko ath6kl_p2p=0x0 ath6kl_roam_mode=0x10 debug_quirks=0x200
sleep 3
busybox ifconfig wlan0 up
if [ $? != 0 ]
then
	exit 1
fi

# Generate wpa_supplicant.conf
echo "Generate wpa_supplicant configuration file ..."
chown wifi.wifi $CONTROL_DIR
chmod 775 $CONTROL_DIR

echo "ctrl_interface=$CONTROL_DIR/sockets" > $CONF
echo "user_mpm=0"                          >> $CONF
echo "fast_reauth=1"                       >> $CONF
echo "dot11RSNAConfigSATimeout=10"         >> $CONF
#WPS
#echo "uuid=12345678-9abc-def0-1234-56789abcdef0" >> $CONF
echo "device_name=Phantom No"              >> $CONF
echo "manufacturer=DJI"                    >> $CONF
echo "model_name=cmodel"                   >> $CONF
echo "model_number=123"                    >> $CONF
echo "serial_number=12345"                 >> $CONF
#echo "os_version=01020300"                >> $CONF
echo "config_methods=label ext_nfc_token int_nfc_token nfc_interface push_button virtual_push_button physical_push_button keypad" >> $CONF
echo "wps_cred_processing=0"               >> $CONF
#echo "wps_vendor_ext_m1=000137100100020001" >> $CONF
#echo "wps_nfc_dev_pw_id: Device Password ID (16..65535)" >> $CONF
#echo "wps_nfc_dh_pubkey: Hexdump of DH Public Key" >> $CONF
#echo "wps_nfc_dh_privkey: Hexdump of DH Private Key" >> $CONF
#echo "wps_nfc_dev_pw: Hexdump of Device Password" >> $CONF

echo "update_config=1"                       >> $CONF
echo "device_type=1-0050F204-1"              >> $CONF
echo "bss_max_count=40"                      >> $CONF
echo "autoscan=periodic:1"                   >> $CONF
#echo "scan_cur_freq: Whether to scan only the current frequency" >> $CONF
#echo "network={"                             >> $CONF
#echo "    ssid=\"$1\""                    >> $CONF
#echo "    key_mgmt=WPA-PSK"                  >> $CONF
#echo "    proto=RSN"                         >> $CONF
#echo "    auth_alg=OPEN"                     >> $CONF
#echo "    pairwise=CCMP"                     >> $CONF
#echo "    psk=\"$2\""                  >> $CONF
#echo "}"                                     >> $CONF
#Using static IP
#busybox ifconfig wlan0 192.168.1.3

# Start wpa_supplicant
echo "start wpa_supplicant ..."
chown wifi:wifi $CONF
chmod 666 $CONF
$WPA_SUPP_CMD -iwlan0 -Dnl80211 -c$CONF -dd &

# Disable power off mode
iw dev wlan0 set power_save off
# Set interface mtu
busybox ifconfig wlan0 mtu 490
