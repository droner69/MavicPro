#!/bin/sh

write_restore_cmd ()
{
	if [ $need_rmmod -eq 1 ]; then
		wlan0=`ifconfig wlan0 | grep "inet addr"`
		wlan0_ip=`echo "${wlan0}" | awk '{print $2}' | cut -d ':' -f 2`
		wlan0_mask=`echo "${wlan0}" | awk '{print $4}' | cut -d ':' -f 2`
	fi

	echo "ifconfig wlan0 up" >> /tmp/wifi_start.sh
	hostapd_cmd=`ps -o args|grep hostapd|grep -v grep`
	if [ "${hostapd_cmd}" != "" ]; then
		echo ${hostapd_cmd} >> /tmp/wifi_start.sh
		return
	fi

	wpa_supplicant_cmd=`ps -o args|grep wpa_supplicant|grep -v grep`
	if [ "${wpa_supplicant_cmd}" != "" ]; then
		echo ${wpa_supplicant_cmd} >> /tmp/wifi_start.sh

		#recover p2p
		wpa_event_cmd=`ps -o args|grep wpa_event|grep -v grep`
		if [ "${wpa_event_cmd}" != "" ]; then
			echo "killall -9 wpa_cli wpa_event.sh" >> /tmp/wifi_start.sh
			if [ -e /sys/module/bcmdhd ]; then
				echo "ifconfig p2p0 up" >> /tmp/wifi_start.sh
			fi
			echo ${wpa_event_cmd} >> /tmp/wifi_start.sh
			echo "wpa_cli p2p_set ssid_postfix \"_AMBA\"" >> /tmp/wifi_start.sh
			echo "wpa_cli p2p_find" >> /tmp/wifi_start.sh
		fi
	fi
}

if [ "${1}" == "fast" ]; then
	cp /dev/null /tmp/wifi_start.sh
	if [ -e /sys/module/8189es ] || [ -e /sys/module/bcmdhd ]; then
		need_rmmod=0
	else
		need_rmmod=1
		#echo "/usr/local/share/script/load.sh fast" >> /tmp/wifi_start.sh
	fi
	write_restore_cmd
	if [ $need_rmmod -eq 1 ]; then
		echo "ifconfig wlan0 ${wlan0_ip} netmask ${wlan0_mask}" >> /tmp/wifi_start.sh
	fi
	chmod a+x /tmp/wifi_start.sh

	if [ -e /sys/module/bcmdhd ]; then
		wl down
		wpa_cli -i wlan0 terminate
	fi
	ifconfig wlan0 down
	killall hostapd wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
	rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
	if [ $need_rmmod -eq 1 ]; then
		/usr/local/share/script/unload.sh fast
		/usr/local/share/script/load.sh fast
	fi
	#send net status update message (Network turned off)
	if [ -x /usr/bin/SendToRTOS ]; then
		/usr/bin/SendToRTOS net_off
	fi
	exit 0
fi

wait_mmc_remove ()
{
	if [ -e /proc/ambarella/mmc_fixed_cd ]; then
		mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
		echo "${mmci} 0" > /proc/ambarella/mmc_fixed_cd
	else
		echo 0 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
	fi
	if [ "${WIFI_EN_STATUS}" == "" ]; then
		WIFI_EN_STATUS=1
	fi
	/usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} $(($(($WIFI_EN_STATUS + 1)) % 2))

	n=0
	while [ "`ls /sys/bus/sdio/devices`" != "" ] && [ $n -ne 30 ]; do
		n=$(($n + 1))
		sleep 0.1
	done
}

#  Note: wpa_supplicant from bcmdhd does not set interface down when exit.
if [ -e /sys/module/bcmdhd ]; then
	# Note: Need wl to set interface "real down".
	wl down
	wpa_cli -i wlan0 terminate
	ifconfig wlan0 down
fi
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
echo "killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh"
rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

if [ "${1}" != "nounload" ]; then
	/usr/local/share/script/unload.sh
fi
conf=`cat /pref/wifi.conf | grep -Ev "^#"`
export `echo "${conf}"|grep -v PASSW|grep -v SSID|grep -vI $'^\xEF\xBB\xBF'`
if [ "${WIFI_EN_GPIO}" != "" ]; then
	wait_mmc_remove
fi

#send net status update message (Network turned off)
if [ -x /usr/bin/SendToRTOS ]; then
	/usr/bin/SendToRTOS net_off
fi
