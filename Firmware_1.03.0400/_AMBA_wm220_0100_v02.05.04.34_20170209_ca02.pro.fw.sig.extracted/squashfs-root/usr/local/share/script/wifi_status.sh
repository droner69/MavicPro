#!/bin/sh

#status
running=`ps|grep -E "(hostapd|wpa_supplicant)"|grep -v grep`
if [ "${running}" == "" ]; then
	echo -n "\"status\":\"disabled\""
	exit 0
fi

#driver
if [ -e /sys/module/ar6000 ]; then
	driver=wext
else
	driver=nl80211
fi

#mode
if [ "${driver}" == "wext" ]; then
	iwcfg=`iwconfig wlan0`
	master=`echo "${iwcfg}"|grep "Mode:Master"`
else
	master=`iw wlan0 info|grep AP`
fi
if [ "${master}" != "" ]; then
	mode="ap"
else
	mode="sta"
fi

#SSID
#sta: STRENGTH
#ap: CONN_amount, CONN_list
if [ "${mode}" == "sta" ]; then
	SSID=`iwgetid |cut -d ':' -f 2|sed 's/"//g'`
	if [ "${driver}" == "wext" ]; then
		STRENGTH=`echo "${iwcfg}"|grep "Signal"|cut -d ':' -f 3|awk '{print $1}'`
	else
		STRENGTH=`iw wlan0 link|grep signal|awk '{print $2}'`
	fi
else
	SSID=`cat /tmp/hostapd.conf 2>/dev/null|grep ssid |grep -Ev "^#"|cut -c 6-`
	if [ "${SSID}" == "" ]; then
		SSID=`cat /tmp/wpa_supplicant.ap.conf|grep ssid| grep -Ev "^#"|cut -d '=' -f 2|sed 's/"//g'`
	fi
	sta_dump=`hostapd_cli all_sta 2>/dev/null|grep -E "^..:..:..:..:..:.."`
	if [ "${sta_dump}" == "" ]; then
		sta_dump=`wpa_cli all_sta 2>/dev/null|grep -E "^..:..:..:..:..:.."`
	fi
	if [ "${sta_dump}" == "" ]; then
		sta_dump=`iw wlan0 station dump | grep Station|awk '{print $2}'`
	fi
	if [ "${sta_dump}" == "" ]; then
		CONN_amount=0
		CONN_list=""
	else
		CONN_amount=`echo "${sta_dump}"|wc -l`
		for i in ${sta_dump}; do
			CONN_list=${CONN_list}\"${i}\",
		done
		CONN_list=`echo $CONN_list|sed 's/,$//'`
	fi
fi

#IP, MAC
IP=`ifconfig wlan0 | grep "inet addr" |cut -d ':' -f 2|awk '{print $1}'`
MAC=`ifconfig wlan0 | grep HWaddr  | awk '{print $NF}'`

#output json
if [ "${mode}" == "sta" ]; then
	echo -n "\"status\":\"enabled\","
	echo -n "\"mode\":\"${mode}\","
	echo -n "\"SSID\":\"${SSID}\","
	echo -n "\"IP\":\"${IP}\","
	echo -n "\"MAC\":\"${MAC}\","
	echo -n "\"STRENGTH\":\"${STRENGTH}db\""
else
	echo -n "\"status\":\"enabled\","
	echo -n "\"mode\":\"${mode}\","
	echo -n "\"SSID\":\"${SSID}\","
	echo -n "\"IP\":\"${IP}\","
	echo -n "\"MAC\":\"${MAC}\","
	echo -n "\"CONN_amount\":\"${CONN_amount}\","
	echo -n "\"CONN_list\":[${CONN_list}]"
fi
