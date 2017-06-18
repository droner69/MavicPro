#!/bin/sh

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
get_p2p_ht20_class()
{
	case ${p2p_oper_channel} in
	1|2|3|4|5|6|7|8|9|10|11)
		p2p_listen_reg_class=81
	;;
	36|40|44|48)
		p2p_listen_reg_class=115
	;;
	52|56|60|64)
		p2p_listen_reg_class=118
	;;
	149|153|157|161)
		p2p_listen_reg_class=124
	;;
	100|104|108|112|116|120|124|128|132|136|140)
		p2p_listen_reg_class=121
	;;
	165)
		p2p_listen_reg_class=125
	;;
	*)
		echo "Usage: invalid channel"
		exit 1
	;;
	esac
}
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

if [ -e /sys/module/ar6000 ]; then
	P2PMODE=`cat /sys/module/ar6000/parameters/submode 2>/dev/null`
	if [ "${P2PMODE}" != "p2pdev" ]; then
		/usr/local/share/script/unload.sh
	fi
	driver=ar6003
else
	driver=nl80211
fi
if [ -e /sys/module/ath6kl_sdio ]; then
	P2PMODE=`cat /sys/module/ath6kl_sdio/parameters/ath6kl_p2p 2>/dev/null`
	if [ "${P2PMODE}" == "0" ]; then
		/usr/local/share/script/unload.sh
	fi
fi

if [ ! -e /tmp/wifi.loaded ]; then
#	syslogd -O /dev/console
	/usr/local/share/script/load.sh p2p
	wait_wlan0
fi

postmac=`ifconfig wlan0 | grep HWaddr | awk '{print $NF}' | sed 's/://g' | cut -c 6- | tr 'A-Z' 'a-z'`
device_name=amba-${postmac}

echo "device_name=${device_name}" > /tmp/p2p.conf
echo "ctrl_interface=/var/run/wpa_supplicant" >> /tmp/p2p.conf
echo "device_type=6-0050F204-1" >> /tmp/p2p.conf
echo "config_methods=display push_button keypad" >> /tmp/p2p.conf

#channel specified
if [ ${1} -gt 0 ]; then
	p2p_oper_channel=${1}
	echo "p2p_go_intent=0" >> /tmp/p2p.conf
	echo "p2p_oper_channel=${p2p_oper_channel}" >> /tmp/p2p.conf
	#echo "p2p_listen_channel=${p2p_oper_channel}" >> /tmp/p2p.conf
	get_p2p_ht20_class
	echo "p2p_oper_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
	echo "p2p_listen_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
	echo "country=US" >> /tmp/p2p.conf
elif [ $# -eq 1 ]; then
	echo "Usage: $0 channel"
	exit 1
fi

wpa_supplicant -i wlan0 -c /tmp/p2p.conf -D ${driver} -B
wpa_cli -B -a /usr/local/share/script/wpa_event.sh
wpa_cli p2p_set ssid_postfix "_AMBA"
wpa_cli p2p_find
