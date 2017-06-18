#!/bin/sh

if [ "${1}" != "" ]; then
	usecache=${1}
fi

reset_conf()
{
	checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
	if [ "${checkfuse}" == "" ]; then
		fuse_d="/tmp/SD0"
	else
		fuse_d="/tmp/fuse_d"
	fi
	echo "config corrupted, reset wifi.conf"
	cp /usr/local/share/script/wifi.conf /pref/wifi.conf
	wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
	echo "${wificonf}" > ${fuse_d}/MISC/wifi.conf
	killall hostapd wpa_supplicant dnsmasq 2>/dev/null
}

# return: 1 as setting as nl80211
chk_nl80211()
{
	# Atheros
	if [ -e /sys/module/ar6000 ]; then
		return 0
	fi

	# Broadcom
	if [ -e /sys/module/dhd ]; then
		return 0
	fi

	return 1
}

hostapd_conf()
{
	if [ "${usecache}" != "" ] && [ -e /tmp/hostapd.conf ]; then
		cat /tmp/hostapd.conf
	else
		#generate hostapd.conf
		echo "interface=wlan0" > /tmp/hostapd.conf
		echo "ctrl_interface=/var/run/hostapd" >> /tmp/hostapd.conf
		echo "beacon_int=100" >> /tmp/hostapd.conf
		echo "dtim_period=1" >> /tmp/hostapd.conf
		echo "preamble=0" >> /tmp/hostapd.conf
		#WPS support
		echo "wps_state=2" >> /tmp/hostapd.conf
		echo "eap_server=1" >> /tmp/hostapd.conf

		#AP_SSID
		echo "AP_SSID=${AP_SSID}"
		echo "ssid=${AP_SSID}" >> /tmp/hostapd.conf

		#AP_MAXSTA
		echo "max_num_sta=${AP_MAXSTA}" >> /tmp/hostapd.conf

		#AP_CHANNEL
		if [ ${AP_CHANNEL} -lt 0 ]; then
			reset_conf
			return 1
		fi

		# TODO: For 5G?!
		if [ ! -e /sys/module/ar6000 ] && [ $AP_CHANNEL -eq 0 ]; then
			#choose 1~10 for HT40
			#RAND_CHANNEL=`echo $(( $RANDOM % 10 +1 ))`
			RAND_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
			echo "channel=${RAND_CHANNEL}" >> /tmp/hostapd.conf
		fi
		if [ $AP_CHANNEL -ne 0 ]; then
			echo "channel=${AP_CHANNEL}" >> /tmp/hostapd.conf
		else
			AP_CHANNEL=${RAND_CHANNEL}
			echo "AP_CHANNEL (randomly)=${AP_CHANNEL}"
		fi

		#WEP, WPA, No Security
		echo "AP_PUBLIC=${AP_PUBLIC}"
		if [ "${AP_PUBLIC}" != "yes" ]; then
			#WPA
			echo "wpa=2" >> /tmp/hostapd.conf
			echo "wpa_pairwise=CCMP" >> /tmp/hostapd.conf
			echo "wpa_passphrase=${AP_PASSWD}" >> /tmp/hostapd.conf
			echo "wpa_key_mgmt=WPA-PSK" >> /tmp/hostapd.conf
		fi

		# Check nl80211
		chk_nl80211
		rval=$?
		if [ ${rval} -eq 1 ]; then
			echo "driver=nl80211" >> /tmp/hostapd.conf
			if [ ${AP_CHANNEL} -gt 14 ]; then
				echo "hw_mode=a" >> /tmp/hostapd.conf
			else
				echo "hw_mode=g" >> /tmp/hostapd.conf
			fi
			echo "ieee80211n=1" >> /tmp/hostapd.conf
			if [ ! -e /sys/module/bcmdhd ]; then
				# TODO: Support HT40 for 5G
				if [ ${AP_CHANNEL} -lt 6 ]; then
					# HT40+ for 1-7 (1-9 in Europe/Japan)
					echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40+]" >> /tmp/hostapd.conf
				else
					# HT40- for 5-13
					echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40-]" >> /tmp/hostapd.conf
				fi
			fi
			#echo "wme_enabled=1" >> /tmp/hostapd.conf
			#echo "wpa_group_rekey=86400" >> /tmp/hostapd.conf

			if [ -e /sys/module/8189es ]; then
				if [ "`uname -r`" != "2.6.38.8" ]; then
					echo "wowlan_triggers=any" >> /tmp/hostapd.conf
				fi
			fi
		fi
	fi
}

wpa_supplicant_conf()
{
	if [ -e /sys/module/ar6000 ]; then
		driver=wext
	else
		driver=nl80211
	fi

	if [ "${usecache}" != "" ] && [ -e /tmp/wpa_supplicant.ap.conf ]; then
		cat /tmp/wpa_supplicant.ap.conf
	else
		#generate /tmp/wpa_supplicant.ap.conf
		echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.ap.conf
		echo "ap_scan=2" >> /tmp/wpa_supplicant.ap.conf

		#AP_MAXSTA
		echo "max_num_sta=${AP_MAXSTA}" >> /tmp/wpa_supplicant.ap.conf

		echo "network={" >> /tmp/wpa_supplicant.ap.conf
		#AP_SSID
		echo "AP_SSID=${AP_SSID}"
		echo "ssid=\"${AP_SSID}\"" >> /tmp/wpa_supplicant.ap.conf

		#AP_CHANNEL
		echo "AP_CHANNEL=${AP_CHANNEL}"
		if [ ${AP_CHANNEL} -lt 0 ]; then
			reset_conf
			return 1
		fi

		# TODO: for 5G
		if [ $AP_CHANNEL -eq 0 ]; then
			#choose 1~10 for HT40
			#AP_CHANNEL=`echo $(( $RANDOM % 11 +1 ))`
			AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
		fi

		# cf. http://en.wikipedia.org/wiki/List_of_WLAN_channels
		if [ $AP_CHANNEL -lt 14 ]; then
			# 2.4G: 2412 + (ch-1) * 5
			echo "frequency=$((2412 + ($AP_CHANNEL - 1) * 5))" >> /tmp/wpa_supplicant.ap.conf
		else
			# 5G: 5000 + ch * 5
			echo "frequency=$((5000 + $AP_CHANNEL * 5))" >> /tmp/wpa_supplicant.ap.conf
		fi

		#WEP, WPA, No Security
		if [ "${AP_PUBLIC}" != "yes" ]; then
			# proto defaults to: WPA RSN
			echo "proto=WPA2" >> /tmp/wpa_supplicant.ap.conf
			echo "pairwise=CCMP" >> /tmp/wpa_supplicant.ap.conf
			echo "group=CCMP" >> /tmp/wpa_supplicant.ap.conf
			echo "psk=\"${AP_PASSWD}\"" >> /tmp/wpa_supplicant.ap.conf
			echo "key_mgmt=WPA-PSK" >> /tmp/wpa_supplicant.ap.conf
		else
			echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.ap.conf
		fi
		echo "mode=2" >> /tmp/wpa_supplicant.ap.conf
		echo "}" >> /tmp/wpa_supplicant.ap.conf
		if [ -e /sys/module/bcmdhd ]; then
			echo "p2p_disabled=1" >> /tmp/wpa_supplicant.ap.conf
			if [ "`uname -r`" != "2.6.38.8" ]; then
				echo "wowlan_triggers=any" >> /tmp/wpa_supplicant.ap.conf
			fi
		fi
	fi
}

bcm_ap_start()
{
	#AP_SSID
	echo "AP_SSID=${AP_SSID}"

	#AP_MAXSTA
	echo "AP_MAXSTA=${AP_MAXSTA}"

	#AP_CHANNEL
	echo "AP_CHANNEL=${AP_CHANNEL}"
	if [ ${AP_CHANNEL} -lt 0 ]; then
		reset_conf
		return 1
	fi
	if [ $AP_CHANNEL -eq 0 ]; then
		#choose 1~10 for HT40
		#AP_CHANNEL=`echo $(( $RANDOM % 11 +1 ))`
		AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
		echo "Random AP_CHANNEL=${AP_CHANNEL}"
	fi

	ifconfig wlan0 down
	wl down
	wl ap 0
	wl ap 1
	wl ssid "$AP_SSID"
	#wl bssmax $AP_MAXSTA
	wl channel $AP_CHANNEL

	#WEP, WPA, No Security
	echo "AP_PUBLIC=${AP_PUBLIC}"

	# auth: set/get 802.11 authentication. 0 = OpenSystem, 1 = SharedKey, 2 = Open/Shared.
	# wpa_auth
	#	Bitvector of WPA authorization modes:
	#	1    WPA-NONE
	#	2    WPA-802.1X/WPA-Professional
	#	4    WPA-PSK/WPA-Personal
	#	64   WPA2-802.1X/WPA2-Professional
	#	128  WPA2-PSK/WPA2-Personal
	#	0    disable WPA
	if [ "${AP_PUBLIC}" != "yes" ]; then
		wl wpa_auth 128

		# wsec  wireless security bit vector
		#	1 - WEP enabled
		#	2 - TKIP enabled
		#	4 - AES enabled
		#	8 - WSEC in software
		#	0x80 - FIPS enabled
		#	0x100 - WAPI enabled
		wl wsec 4

		echo "AP_PASSWD=${AP_PASSWD}"
		wl set_pmk "$AP_PASSWD"
	else
		wl auth 0
		wl wpa_auth 0
		wl wsec 0
	fi

	wl mpc 0
	wl frameburst 1
	wl up
	ifconfig wlan0 up

	return 0
}

apply_ap_conf()
{
	#LOCAL_IP
	killall udhcpc
	ifconfig wlan0 $LOCAL_IP
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi
	#route add default gw $LOCAL_IP

	#LOCAL_NETMASK
	ifconfig wlan0 netmask $LOCAL_NETMASK
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	#DHCP_IP_START DHCP_IP_END

	nets=`ls /sys/class/net/|grep -v lo|grep -v wlan|grep -v p2p|grep -v ap`
	for lte in ${nets}; do
		eth=`echo "${lte}" | grep eth`
		if [ "${eth}" == "" ]; then
			#qualcomm ppp0 or wwan0
			mobile=1
			break
		else
			#altair eth1
			cdc_ether=`readlink /sys/class/net/${eth}/device/driver|grep cdc_ether`
			if [ "${cdc_ether}" != "" ]; then
				mobile=1
				break
			fi
		fi
	done

	if [ "${mobile}" == "1" ]; then
		dnsmasq -5 -K --log-queries --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
	else
		dnsmasq --nodns -5 -K -R -n --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
	fi

	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	if [ -e /sys/module/dhd ]; then
		# Broadcom bcm43362, etc.
		bcm_ap_start
		rval=$?
	else
		which hostapd
		if [ $? -ne 0 ] || [ -e /sys/module/ath6kl_sdio ]; then
			wpa_supplicant_conf
			rval=$?
			if [ ${rval} -ne 0 ]; then
				reset_conf
				return 1
			fi
			wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.ap.conf -B
			rval=$?
		else
			hostapd_conf
			rval=$?
			if [ ${rval} -ne 0 ]; then
				reset_conf
				return 1
			fi
			hostapd -B /tmp/hostapd.conf
			rval=$?
		fi
	fi

	if [ ${rval} -ne 0 ]; then
		reset_conf
		return 1
	fi
	if [ -e /sys/module/ar6000 ] && [ $AP_CHANNEL -eq 0 ]; then
		#ACS (Automatic Channel Selection) between 1, 6, 11
		iwconfig wlan0 channel 0
		iwconfig wlan0 commit
	fi

	#send net status update message (Network ready, AP mode)
	if [ -x /usr/bin/SendToRTOS ]; then
		/usr/bin/SendToRTOS net_ready 0
	elif [ -x /usr/bin/boot_done ]; then
		boot_done 1 2 1
	fi

	return 0
}

#Load the parameter settings
apply_ap_conf
rval=$?
echo -e "rval=${rval}\n"
if [ ${rval} -ne 0 ]; then
	killall -9 hostapd wpa_supplicant dnsmasq 2>/dev/null
	apply_ap_conf
fi
