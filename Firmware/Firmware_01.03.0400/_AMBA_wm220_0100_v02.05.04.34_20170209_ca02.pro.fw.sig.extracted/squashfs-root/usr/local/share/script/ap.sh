#!/bin/sh

get_ht40()
{
	case ${channel} in
	36|44|52|60|149|157)
		HT="[HT40+]"
	;;
	40|48|56|64|153|161)
		HT="[HT40-]"
	;;
	*)
		HT=""
	;;
	esac
}

wait_wlan0()
{
	n=0
	ifconfig wlan0
	waitagain=$?
	while [ $n -ne 6 ] && [ $waitagain -ne 0 ]; do
		n=$(($n + 1))
		echo $n
		sleep 1
		ifconfig wlan0
		waitagain=$?
	done
}

killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

if [ ! -e /tmp/wifi.loaded ]; then
	/usr/local/share/script/load.sh ap
	wait_wlan0
fi

if [ "${1}" == "" ]; then
	echo "specify SoftAP SSID, for example ${0} amba_boss"
	echo "specify channel & SoftAP SSID, for example ${0} amba_boss 40"
	exit 0
fi

SSID=${1}
channel=1
frequency=2412
if [ "${2}" != "" ]; then
	channel=${2}
	if [ $channel -lt 14 ]; then
		frequency=$((2412 + ($channel - 1) * 5))
	else
		frequency=$((5000 + $channel * 5))
	fi
fi

if [ -e /sys/module/ath6kl_sdio ] || [ -e /sys/module/bcmdhd ] ; then
	cp /usr/local/share/script/wpa_supplicant.ap.conf /tmp/
	sed -i 's|amba_boss|'${SSID}'|g' /tmp/wpa_supplicant.ap.conf
	sed -i 's|frequency=1|frequency='${frequency}'|g' /tmp/wpa_supplicant.ap.conf
	if [ -e /sys/module/bcmdhd ]; then
		echo "p2p_disabled=1" >> /tmp/wpa_supplicant.ap.conf
	fi

	ifconfig wlan0 192.168.42.1
	dnsmasq --nodns -5 -K -R -n --dhcp-range=192.168.42.2,192.168.42.6,infinite
	wpa_supplicant -Dnl80211 -iwlan0 -c/tmp/wpa_supplicant.ap.conf -B
else
	cp /usr/local/share/script/hostapd.conf /tmp/
	sed -i 's|amba_boss|'${SSID}'|g' /tmp/hostapd.conf
	sed -i 's|channel=1|channel='${channel}'|g' /tmp/hostapd.conf

	if [ ! -e /sys/module/ar6000 ]; then
		echo "driver=nl80211" >> /tmp/hostapd.conf
		echo "ieee80211n=1" >> /tmp/hostapd.conf
		if [ ${channel} -lt 6 ]; then
			# HT40+ for 1-7 (1-9 in Europe/Japan)
			echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40+]" >> /tmp/hostapd.conf
		elif  [ ${channel} -gt 14 ]; then
			get_ht40
			sed -i 's|hw_mode=g|hw_mode=a|g' /tmp/hostapd.conf
			echo "ht_capab=[SHORT-GI-20][SHORT-GI-40]${HT}" >> /tmp/hostapd.conf
		else
			echo "ht_capab=[SHORT-GI-20][SHORT-GI-40][HT40-]" >> /tmp/hostapd.conf
		fi
	fi

	ifconfig wlan0 192.168.42.1
	dnsmasq --nodns -5 -K -R -n --dhcp-range=192.168.42.2,192.168.42.6,infinite
	hostapd -B /tmp/hostapd.conf
fi

