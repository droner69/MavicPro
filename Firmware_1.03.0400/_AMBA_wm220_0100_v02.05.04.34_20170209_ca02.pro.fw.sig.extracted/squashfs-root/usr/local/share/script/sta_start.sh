#!/bin/sh

if [ -e /sys/module/ar6000 ]; then
	driver=wext
elif [ -e /sys/module/dhd ]; then
	driver=wext
	wl ap 0
	wl mpc 0
	wl frameburst 1
	wl up
else
	driver=nl80211
fi

wait_ip_done ()
{
	n=0
	wlan0_ready=`ifconfig wlan0|grep "inet addr"`
	while [ "${wlan0_ready}" == "" ] && [ $n -ne 10 ]; do
		wlan0_ready=`ifconfig wlan0|grep "inet addr"`
		n=$(($n + 1))
		sleep 1
	done

	if [ "${wlan0_ready}" != "" ]; then
		#send net status update message (Network ready, STA mode)
		if [ -x /usr/bin/SendToRTOS ]; then
			/usr/bin/SendToRTOS net_ready 1
		elif [ -x /usr/bin/boot_done ]; then
			boot_done 1 2 1
		fi
	else
		echo "Cannot get IP within 10 sec, skip boot_done"
	fi
}

checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
if [ "${checkfuse}" == "" ]; then
	fuse_d="/tmp/SD0"
else
	fuse_d="/tmp/fuse_d"
fi

if [ "${1}" != "" ] && [ -e /tmp/wpa_supplicant.conf ]; then
	cat /tmp/wpa_supplicant.conf
	wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
	udhcpc -i wlan0 -A 1 -b
	wait_ip_done
	exit 0
fi

FORCE_RESCAN_TIMES=8

WPA_SCAN ()
{
	if [ -e /sys/module/bcmdhd ]; then
		echo "p2p_disabled=1" > /tmp/wpa_scan.conf
		wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B -c /tmp/wpa_scan.conf
	else
		wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B
	fi
	wpa_cli scan
	echo "start scan for ${ESSID}"
	sleep 1
	scan_result=`wpa_cli scan_r`
	scan_entry=`echo "${scan_result}" | tr '\t' ' ' | grep " ${ESSID}$" | tail -n 1`
	echo "${scan_result}"
	n=1
	while [ "${scan_entry}" == "" ] && [ $n -ne 8 ]; do
		echo sleep 0.5; sleep 0.5
		n=$(($n + 1))
		scan_result=`wpa_cli scan_r`
		echo "${scan_result}"
		scan_entry=`echo "${scan_result}" | tr '\t' ' ' | grep " ${ESSID}$" | tail -n 1`
	done
}

WPA_GO ()
{
	killall -9 wpa_supplicant 2>/dev/null
	wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
	udhcpc -i wlan0 -A 1 -b
	wait_ip_done
}

if [ "${STA_SKIP_SCAN}" == "yes" ]; then
	sdvalid=`grep ${ESSID} ${fuse_d}/MISC/wpa_supplicant.conf 2>/dev/null`
	if [ "${sdvalid}" != "" ]; then
		echo -e "\033[031m use previous config cache in ${fuse_d}/MISC/wpa_supplicant.conf: \033[0m"
		cp ${fuse_d}/MISC/wpa_supplicant.conf /tmp/
		cat /tmp/wpa_supplicant.conf
		WPA_GO
		exit 0
	else
		echo -e "\033[031m cannot find previous config cache in ${fuse_d}/MISC/wpa_supplicant.conf \033[0m"
	fi
fi

WPA_SCAN
killall wpa_supplicant
if [ "${scan_entry}" == "" ]; then
	scan_retry=1
	while [ "${scan_entry}" == "" ] && [ $scan_retry -ne $FORCE_RESCAN_TIMES ]; do
		echo -e "\e[1;35m $0 will retry for $FORCE_RESCAN_TIMES times, start re-scan $scan_retry \e[0m"
		WPA_SCAN
		killall wpa_supplicant
		scan_retry=$(($scan_retry + 1))
	done
fi

if [ "${scan_entry}" == "" ]; then
	echo -e "\033[031m failed to detect SSID ${ESSID}, use /usr/local/share/script/wpa_supplicant.conf: \033[0m"
	cp /usr/local/share/script/wpa_supplicant.conf /tmp/
	cat /tmp/wpa_supplicant.conf
	WPA_GO
	exit 0
fi

echo -e "\033[031m ${scan_entry} \033[0m"
echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
echo "network={" >> /tmp/wpa_supplicant.conf
echo "ssid=\"${ESSID}\"" >> /tmp/wpa_supplicant.conf
echo "scan_ssid=1" >> /tmp/wpa_supplicant.conf
WEP=`echo "${scan_entry}" | grep WEP`
WPA=`echo "${scan_entry}" | grep WPA`
WPA2=`echo "${scan_entry}" | grep WPA2`
CCMP=`echo "${scan_entry}" | grep CCMP`
TKIP=`echo "${scan_entry}" | grep TKIP`

if [ "${WPA}" != "" ]; then
	#WPA2-PSK-CCMP	(11n requirement)
	#WPA-PSK-CCMP
	#WPA2-PSK-TKIP
	#WPA-PSK-TKIP
	echo "key_mgmt=WPA-PSK" >> /tmp/wpa_supplicant.conf

	if [ "${WPA2}" != "" ]; then
		echo "proto=WPA2" >> /tmp/wpa_supplicant.conf
	else
		echo "proto=WPA" >> /tmp/wpa_supplicant.conf
	fi

	if [ "${CCMP}" != "" ]; then
		echo "pairwise=CCMP" >> /tmp/wpa_supplicant.conf
	else
		echo "pairwise=TKIP" >> /tmp/wpa_supplicant.conf
	fi

	echo "psk=\"${PASSWORD}\"" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" != "" ] && [ "${WPA}" == "" ]; then
	echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
        echo "wep_key0=${PASSWORD}" >> /tmp/wpa_supplicant.conf
        echo "wep_tx_keyidx=0" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" == "" ] && [ "${WPA}" == "" ]; then
	echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
fi

echo "}" >> /tmp/wpa_supplicant.conf

if [ -e /sys/module/bcmdhd ]; then
	rm -f /tmp/wpa_scan.conf
	echo "p2p_disabled=1" >> /tmp/wpa_supplicant.conf
	if [ "`uname -r`" != "2.6.38.8" ]; then
		echo "wowlan_triggers=any" >> /tmp/wpa_supplicant.conf
	fi
fi
if [ -e /sys/module/8189es ] || [ -e /sys/module/8723bs ]; then
	if [ "`uname -r`" != "2.6.38.8" ]; then
		echo "wowlan_triggers=any" >> /tmp/wpa_supplicant.conf
	fi
fi

if [ -e ${fuse_d}/MISC/ ]; then
	cp /tmp/wpa_supplicant.conf ${fuse_d}/MISC/wpa_supplicant.conf
fi
WPA_GO
