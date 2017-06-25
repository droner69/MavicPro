#!/bin/sh

## called from kernel call_usermodehelper, return quickly
if [ "${1}" == "resume" ]; then
	if [ -e /sys/module/8189es ]; then
		MODE=`iw wlan0 info | grep type  | awk '{print $2}'`
		if [ "${MODE}" == "AP" ] || [ "${MODE}" == "P2P-GO" ]; then
			# AP, P2P-GO
			iwpriv wlan0 ap_wow_mode disable
		else
			# Stationi, P2P-Client  mode wow
			iwpriv wlan0 wow_mode disable
		fi
	elif [ -e /sys/module/8723bs ]; then
		# Station mode wow
		iwpriv wlan0 wow_mode disable
	fi
	exit 0
fi

if [ -e /sys/module/bcmdhd ]; then
	#filter index=200, byte36=0x1E, byte37=0xC5; udp.dstport == 7877
	wl pkt_filter_add 200 0 0 36 0xffff 0x1EC5
	wl pkt_filter_enable 200 1
elif [ -e /sys/kernel/debug/ieee80211/phy0/ath6kl/wow_pattern ]; then
	#filter index=0, byte44=0x1E, byte45=0xC5; udp.dstport == 7877
	iw wlan0 wowlan enable disconnect
	echo -en '\x1E\xC5' > /tmp/match.bin
	echo 0 44 /tmp/match.bin > /sys/kernel/debug/ieee80211/phy0/ath6kl/wow_pattern
elif [ -e /sys/module/ar6000 ]; then
	wmiconfig -i wlan0 --sethostmode asleep
	wmiconfig -i wlan0 --setwowmode enable
	# Edit here to Customize Magic Packet filter
	echo "This example uses ip.protocol=UDP AND UDP.dst_port=7877 as wakeup packet"
	wmiconfig -i wlan0 --addwowpattern 0 15 31 110000000000000000000000001EC5 FF000000000000000000000000FFFF
	# wait 1 sec to take effect
	sleep 1
elif [ -e /sys/module/8189es ]; then
	MODE=`iw wlan0 info | grep type  | awk '{print $2}'`
	if [ "${MODE}" == "AP" ] || [ "${MODE}" == "P2P-GO" ]; then
		# AP, P2P-GO
		iwpriv wlan0 ap_wow_mode enable
	else
		# Stationi, P2P-Client  mode wow
		iwpriv wlan0 wow_mode enable
	fi
elif [ -e /sys/module/8723bs ]; then
	# Station mode wow
	iwpriv wlan0 wow_mode enable
fi

brcm_bt=`ps|grep brcm_patchram_plus|grep -v grep`
if [ "${brcm_bt}" != "" ]; then
	echo "apply workaround for hci tx timeout err: wakeup BT before suspend, let hardware control btwake during suspend"
	echo 0 > /proc/bluetooth/sleep/btwake
fi

# disable iscan to save BT power
#which bluetoothctl && echo 'discoverable off'| bluetoothctl

# drop cache
echo 3 > /proc/sys/vm/drop_caches

# enter self refresh mode
if [ "${1}" == "" ]; then
	echo sr > /sys/power/state
fi
