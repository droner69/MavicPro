#! /system/bin/sh

### BEGIN INFO
# Used to test WIFI STA link
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

if [ -z "$1" -o -z "$2" -o -z "$3" ]
then
    echo "Usage: test_wifi.sh <ssid> <password> <ip addr> [loop number]"
    exit 1
fi

SSID=\"$1\"
PSK=\"$2\"
PING_IP=$3

# Connect a network
echo "Connect AP ..."
wpa_cli -g /data/misc/wifi/sockets/wlan0 remove_network 0
wpa_cli -g /data/misc/wifi/sockets/wlan0 scan
wpa_cli -g /data/misc/wifi/sockets/wlan0 add_network
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 auth_alg OPEN
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 key_mgmt WPA-PSK
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 psk $PSK
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 proto RSN
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 mode 0
wpa_cli -g /data/misc/wifi/sockets/wlan0 set_network 0 ssid $SSID
wpa_cli -g /data/misc/wifi/sockets/wlan0 select_network 0
wpa_cli -g /data/misc/wifi/sockets/wlan0 enable_network 0

# Check WPA status
WPA_STATUS_CHECK_COUNT=20
CHECK_COUNT=0
while [ $CHECK_COUNT -lt $WPA_STATUS_CHECK_COUNT ]
    do
	CHECK_COUNT=`busybox expr $CHECK_COUNT + 1`
        wpa_cli -g /data/misc/wifi/sockets/wlan0 status | grep wpa_state=COMPLETED
        if [ $? = 0 ]
        then
            echo "Connected, Start DHCP"
            break
        else
            sleep 1
            echo "Waiting for Connected..."
        fi
    done
# DHCP
# Kill dhcpcd
DHCPCD_PID_FILE=/data/misc/dhcp/dhcpcd-wlan0.pid
if [ `ps | grep -c dhcpcd` -gt 0 ]
then
	echo "kill process dhcpcd first"
	kill `ps | grep dhcpcd | busybox awk -F ' ' '{print $2}'`
	if [ -f "$DHCPCD_PID_FILE" ]
	then
	    rm $DHCPCD_PID_FILE
	fi
fi
# DHCP procedure
dhcpcd wlan0 --noipv4ll
if [ $? = 0 ]
then
echo "DHCP Success"
else
echo "DHCP Failed"
exit -1
fi

#Ping the connected AP
echo "Ping AP"
LOOPS=$4
CT=0
PASS_NO=0
RETVAL=-1

if [ -z "$4"]
then
    LOOPS=2  # use default loops number
fi
# ping loop
while [ $CT -lt $LOOPS ]
    do
        if [ $PASS_NO != 0 ]
        then
            break
        fi
        CT=`busybox expr $CT + 1`
        echo "------------${CT} times----------------"
        RESULT=`busybox ping -s $CT -c 1 $PING_IP`
        echo $RESULT | grep " 0% packet loss"
        if [ $? = 0 ]
        then
            echo "-------- ${CT} time PASS-------- "
            PASS_NO=`busybox expr $PASS_NO + 1`
        else
            echo "FAIL: ${CT} time failed while ping AP"
        fi
    done
# if pass ratio reaches 90% return 0, else return -1
#PASS_EXPECT=`busybox expr $LOOPS \* 9`
#PASS_EXPECT=`busybox expr $PASS_EXPECT \/ 10`
#echo "The expected pass number is ${PASS_EXPECT}"
#      if [ $PASS_NO -lt $PASS_EXPECT ]
#      then
#	echo "Test Result: FAILED!"
#        RETVAL=-1
#      else
#	echo "Test Result: PASSED!"
#        RETVAL=0
#      fi
#      echo "Total PASS time: $PASS_NO "
if [ $PASS_NO -le 0 ]
then
    echo "Wi-Fi link test FAILED"
    RETVAL=-1
else
    echo "Wi-Fi link test PASSED"
    RETVAL=0
fi
exit $RETVAL
