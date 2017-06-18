#!/bin/sh
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
}

get_p2p_ht20_class()
{
	case ${P2P_OPER_CHANNEL} in
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
		reset_conf
		exit 1
	;;
	esac
}

get_p2p_ht40_class()
{
	case ${P2P_OPER_CHANNEL} in
	1|2|3|4|5)
		p2p_listen_reg_class=83
	;;
	6|7|8|9|10|11)
		p2p_listen_reg_class=84
	;;
	36|44)
		p2p_listen_reg_class=116
	;;
	52|60)
		p2p_listen_reg_class=119
	;;
	100|108|116|124|132)
		p2p_listen_reg_class=122
	;;
	149|157)
		p2p_listen_reg_class=126
	;;
	40|48)
		p2p_listen_reg_class=117
	;;
	56|64)
		p2p_listen_reg_class=120
	;;
	104|112|120|128|136)
		p2p_listen_reg_class=123
	;;
	153|161)
		p2p_listen_reg_class=127
	;;
	*)
		echo "Usage: invalid channel"
		reset_conf
		exit 1
	;;
	esac
}

if [ -e /sys/module/ar6000 ]; then
	driver=ar6003
else
	driver=nl80211
fi

kver=`uname -r | awk -F '.' '{print $1}'`
if [ -e /sys/module/bcmdhd ]; then
	if [ ${kver} -ge 3 ]; then
	    # bcmdhd with Linux-3.x and later
		bcmdhd=3
	else
	    # bcmdhd with Linux-2.6.x
		bcmdhd=2
	fi
else
	# Not bcmdhd
	bcmdhd=0
fi

if [ "${1}" != "" ] && [ -e /tmp/p2p.conf ]; then
	cat /tmp/p2p.conf
else
	echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/p2p.conf
	echo "device_type=6-0050F204-1" >> /tmp/p2p.conf
	echo "config_methods=display push_button keypad" >> /tmp/p2p.conf
	echo "persistent_reconnect=1" >> /tmp/p2p.conf

	#device_name
	if [ "${P2P_DEVICE_NAME}" == "" ]; then
		postmac=`ifconfig wlan0 | grep HWaddr | awk '{print $NF}' | sed 's/://g' | cut -c 6- | tr 'A-Z' 'a-z'`
		P2P_DEVICE_NAME=amba-${postmac}
	fi
	echo "device_name=${P2P_DEVICE_NAME}" >> /tmp/p2p.conf

	#p2p_go_intent
	if [ "${P2P_GO_INTENT}" != "" ]; then
		echo "p2p_go_intent=${P2P_GO_INTENT}" >> /tmp/p2p.conf
	fi

	#p2p_go_ht40
	if [ "${P2P_GO_HT40}" == "1" ]; then
		echo "p2p_go_ht40=${P2P_GO_HT40}" >> /tmp/p2p.conf
	fi

	#p2p_oper_channel
	if [ "${P2P_OPER_CHANNEL}" != "" ]; then
		echo "p2p_oper_channel=${P2P_OPER_CHANNEL}" >> /tmp/p2p.conf
		#echo "p2p_listen_channel=${P2P_OPER_CHANNEL}" >> /tmp/p2p.conf
		if [ "${P2P_GO_HT40}" == "1" ]; then
			get_p2p_ht40_class
		else
			get_p2p_ht20_class
		fi
		echo "p2p_oper_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
		echo "p2p_listen_reg_class=${p2p_listen_reg_class}" >> /tmp/p2p.conf
		echo "country=US" >> /tmp/p2p.conf
	fi
fi

if [ -e /sys/module/bcmdhd ]; then
	if [ ${kver} -le 2 ]; then
		echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
		echo "driver_param=use_multi_chan_concurrent=1" >> /tmp/wpa_supplicant.conf
		echo "p2p_disabled=1" >> /tmp/wpa_supplicant.conf
		echo "driver_param=use_p2p_group_interface=1use_multi_chan_concurrent=1" >> /tmp/p2p.conf
		ifconfig wlan0 up && ifconfig p2p0 up
		wpa_supplicant -i p2p0 -c /tmp/p2p.conf -D nl80211 -N -i wlan0 -c /tmp/wpa_supplicant.conf -D nl80211 -B
		wpa_cli -i p2p0 -B -a /usr/local/share/script/wpa_event.sh
		wpa_cli -i p2p0 p2p_set ssid_postfix "_AMBA"
		wpa_cli -i p2p0 p2p_find
	else
		echo "driver_param=use_p2p_group_interface=1p2p_device=1" >> /tmp/p2p.conf
		cp -f /tmp/p2p.conf /tmp/wpa_supplicant.conf
		echo "ap_scan=1" >> /tmp/wpa_supplicant.conf
		sed -i -e 's/ctrl_interface.*//g' /tmp/p2p.conf
		ifconfig wlan0 up
		wpa_supplicant -i wlan0 -c /tmp/wpa_supplicant.conf -D nl80211 -m /tmp/p2p.conf -g /var/run/bcmdhd_p2p -B
		wpa_cli -i bcmdhd_p2p -p /var/run -B -a /usr/local/share/script/wpa_event.sh
		wpa_cli -i bcmdhd_p2p -p /var/run -B p2p_set ssid_postfix "_AMBA"
		wpa_cli -i bcmdhd_p2p -p /var/run -B p2p_find
	fi
else
	wpa_supplicant -i wlan0 -c /tmp/p2p.conf -D ${driver} -B
	wpa_cli -B -a /usr/local/share/script/wpa_event.sh
	wpa_cli p2p_set ssid_postfix "_AMBA"
	wpa_cli p2p_find
fi

#send net status update message (Network ready, P2P mode)
if [ -x /usr/bin/SendToRTOS ]; then
	/usr/bin/SendToRTOS net_ready 2
elif [ -x /usr/bin/boot_done ]; then
	boot_done 1 2 1
fi
