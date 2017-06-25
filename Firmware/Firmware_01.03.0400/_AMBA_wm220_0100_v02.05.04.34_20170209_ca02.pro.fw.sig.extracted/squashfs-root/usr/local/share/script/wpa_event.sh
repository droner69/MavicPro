#!/bin/sh
#/*
# * Author:
# *	Michael Yao<ccyao@ambarella.com>
# *
# * Copyright (C) 2013, Ambarella Inc.
# */

IFNAME=$1
CMD=$2

sysl=`ps | grep syslogd | grep -v grep`
LOGGER ()
{
	if [ "${sysl}" == "" ]; then
		echo "$@"
	else
		logger "$@"
	fi
}

if [ "${IFNAME}" == "" ] || [ "${CMD}" == "" ]; then
	echo "wrong usage"
	exit 0
fi

LOGGER "$@"

if [ "${IFNAME}" == "bcmdhd_p2p" ]; then
	WPA_CLI_ARG="wpa_cli -i ${IFNAME} -p /var/run"
else
	WPA_CLI_ARG="wpa_cli -i ${IFNAME}"
fi

WPA_CLI ()
{
	if [ "${IFNAME}" == "bcmdhd_p2p" ]; then
		LOGGER " $ wpa_cli -i ${IFNAME} -p /var/run $@"
		wpa_cli -i ${IFNAME} -p /var/run $@
	else
		LOGGER " $ wpa_cli -i ${IFNAME} $@"
		wpa_cli -i ${IFNAME} $@
	fi
}

getP2PIF ()
{
	if [ -e /sys/module/bcmdhd ]; then
		kver=`uname -r | cut -d '.' -f 1`
		if [ ${kver} -eq 2 ]; then
			P2PIF=p2p-p2p0-0
		else
			P2PIF=`ls /sys/class/net/|grep "p2p-wlan"`
		fi
	else
		P2PIF=${IFNAME}
	fi

	if [ -e /sys/module/bcmdhd ] && [ ${kver} -eq 3 ]; then
		n=0
		while [ "${P2PIF}" == "" ] && [ $n -ne 2 ]; do
			all_net=`ls /sys/class/net/`
			LOGGER "ls /sys/class/net/: ${all_net}"
			P2PIF=`echo "${all_net}"|grep "p2p-wlan"`
			n=$(($n + 1))
			sleep 0.5
		done
		LOGGER "P2PIF=${P2PIF}"
	fi

	if [ "${P2PIF}" == "" ]; then
		LOGGER "err: cannot find p2p interface"
	fi
}

auto_pbc_join ()
{
	# Join existing p2p network
	LOGGER "${WPA_CLI_ARG} p2p_peer $pp"
	pr=`${WPA_CLI_ARG} p2p_peer $pp 2>&1`
	LOGGER "$pr"
	pgo=`echo "$pr" | grep "oper_ssid" | grep DIRECT`
	pmatch=`echo "$pr" | grep device_name | grep "${P2P_CONNECT_PREFIX}"`
	if [ "${pgo}" != "" ] && [ "${pmatch}" != "" ] && [ ! -e /tmp/wpa_p2p_done ]; then
		WPA_CLI p2p_connect ${pp} pbc join
		touch /tmp/wpa_p2p_done
		LOGGER " Join ${pp} "
		exit 0
	fi
}

auto_pbc_go ()
{
	# Make sure we create ONLY ONE p2p network for others to join
	pr=`${WPA_CLI_ARG} p2p_peer $pp 2>&1`
	ready1=`echo "$pr" | grep wps_method | grep PBC`
	ready2=`echo "$pr" | grep member_in_go_dev | grep 00:00:00:00:00:00`
	pgo=`echo "$pr" | grep "oper_ssid" | grep DIRECT`
	pmatch=`echo "$pr" | grep device_name | grep "${P2P_CONNECT_PREFIX}"`
	if [ "${ready1}" != "" ] && [ "${ready2}" != "" ]; then
		if [ "${pgo}" == "" ] && [ "${pmatch}" != "" ] && [ ! -e /tmp/wpa_p2p_done ]; then
			WPA_CLI p2p_connect ${pp} pbc
			touch /tmp/wpa_p2p_done
			LOGGER " Making the first attempt for WiFi Direct Network "
			exit 0
		fi
	fi
}

monitor ()
{
	if [ "${conf}" == "" ]; then
		conf=`cat /pref/wifi.conf | grep -Ev "^#"`
	fi
	P2P_AUTO_CONNECT=`echo "${conf}" | grep P2P_AUTO_CONNECT | cut -c 18-`
	if [ "${P2P_AUTO_CONNECT}" != "yes" ]; then
		exit 0
	fi
	P2P_CONNECT_PREFIX=`echo "${conf}"| grep P2P_CONNECT_PREFIX |cut -c 20-`
	if [ "${P2P_CONNECT_PREFIX}" == "" ]; then
		exit 0
	fi

	mac=`ifconfig ${IFNAME} | grep HWaddr | awk '{print $NF}' | sed 's/://g'`
	me=`printf "%d" 0x${mac}`

	while [ ! -e /tmp/wpa_p2p_done ]; do
		peer1=`${WPA_CLI_ARG} p2p_peers | grep -v Selected`
		smallest=1
		for pp in ${peer1}; do
			auto_pbc_join
			mac=`echo ${pp} | sed 's/://g'`
			peer=`printf "%d" 0x${mac}`
			if [ $me -gt $peer ]; then
				smallest=0
			fi
		done

		# Algorithm: Only smallest MAC make connection
		if [ $smallest -ne 1 ]; then
			sleep 5
			continue
		fi

		# wait for new peers
		peer2=`${WPA_CLI_ARG} p2p_peers | grep -v Selected`
		if [ "${peer1}" != "${peer2}" ]; then
			sleep 5
			continue
		fi

		for pp in ${peer2}; do
			auto_pbc_go
		done
		sleep 5
	done
	exit 0
}

if [ ! -e /tmp/wpa_last_event ] && [ ! -e /tmp/wpa_p2p_done ]; then
	monitor &
fi

date +%s > /tmp/wpa_last_event

reset_conf()
{
	checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
	if [ "${checkfuse}" == "" ]; then
		fuse_d="/tmp/SD0"
	else
		fuse_d="/tmp/fuse_d"
	fi
	LOGGER "config corrupted, reset wifi.conf"
	cp /usr/local/share/script/wifi.conf /pref/wifi.conf
	wificonf=`cat /pref/wifi.conf | sed -e 's/$/\r/'`
	echo "${wificonf}" > ${fuse_d}/MISC/wifi.conf
	killall -9 udhcpc hostapd dnsmasq 2>/dev/null
	WPA_CLI p2p_find
}

p2p_client ()
{
	P2P_GO=0
	killall udhcpc hostapd dnsmasq 2>/dev/null
	getP2PIF
	udhcpc -i ${P2PIF} -A 1 -b
}

p2p_go ()
{
	P2P_GO=1
	killall udhcpc hostapd dnsmasq 2>/dev/null
	if [ "${conf}" == "" ]; then
		conf=`cat /pref/wifi.conf | grep -Ev "^#"`
	fi

	#LOCAL_IP
	LOCAL_IP=`echo "${conf}" | grep LOCAL_IP | cut -c 10-`
	LOGGER "LOCAL_IP=${LOCAL_IP}"
	killall udhcpc
	getP2PIF
	ifconfig ${P2PIF} $LOCAL_IP
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi
	route add default gw $LOCAL_IP

	#LOCAL_NETMASK
	LOCAL_NETMASK=`echo "${conf}" | grep LOCAL_NETMASK | cut -c 15-`
	ifconfig ${P2PIF} netmask $LOCAL_NETMASK
	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi

	#DHCP_IP_START DHCP_IP_END
	DHCP_IP_START=`echo "${conf}" | grep DHCP_IP_START | cut -c 15-`
	DHCP_IP_END=`echo "${conf}" | grep DHCP_IP_END | cut -c 13-`
	LOGGER "dnsmasq --nodns -5 -K -R -n --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite"
	dnsmasq --nodns -i ${P2PIF} -5 -K -R -n --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite

	if [ $? -ne 0 ]; then
		reset_conf
		return 1
	fi
}

p2p_reset()
{
	killall udhcpc hostapd dnsmasq 2>/dev/null
	WPA_CLI p2p_cancel
	WPA_CLI p2p_group_remove ${IFNAME}
	WPA_CLI p2p_flush
	rm /tmp/wpa_p2p_done /tmp/wpa_last_event
	WPA_CLI p2p_stop_find
	WPA_CLI p2p_find
}

#${IFNAME} P2P-DEVICE-FOUND 2a:98:7b:d3:c7:ed p2p_dev_addr=2a:98:7b:d3:c7:ed pri_dev_type=10-0050F204-5 name=Android_35a0 config_methods=0x188 dev_capab=0x27 group_capab=0x0
#${IFNAME} P2P-DEVICE-FOUND 00:03:7f:04:e0:9b p2p_dev_addr=00:03:7f:04:e0:9b pri_dev_type=6-0050F204-1 name=AR6003-1 config_methods=0x2388 dev_capab=0x23 group_capab=0x0
if [ "$CMD" == "P2P-DEVICE-FOUND" ]; then
	WPA_CLI p2p_connect ${3} pbc auth
fi

#${IFNAME} P2P-GROUP-STARTED ${IFNAME} GO ssid=DIRECT-AN freq=2437 passphrase=Ooj4S5D1 go_dev_addr=00:03:7f:04:e0:99
#${IFNAME} P2P-GROUP-STARTED ${IFNAME} client ssid="DIRECT-FY" freq=2437 passphrase="JBmB9RjP" go_dev_addr=00:03:7f:dd:ee:ff
#${IFNAME} P2P-GROUP-STARTED ${IFNAME} client ssid=DIRECT-Uo-android344 freq=2462 psk=ddbdcde17f1e59f8111b3697b04b309f23fdde75a3d98f8d4fc882f7140c0afa go_dev_addr=86:7a:88:70:af:7e [PERSISTENT]
if [ "$CMD" == "P2P-GROUP-STARTED" ]; then
	ssid=`echo "${5}" | grep ssid | grep DIRECT`
	echo "${5}" | cut -d '=' -f 2 > /tmp/DIRECT.ssid
	echo "${7}" | cut -d '=' -f 2 > /tmp/DIRECT.passphrase
	if [ "$4" = "GO" ] && [ "${ssid}" != "" ]; then
		p2p_go
	fi
	if [ "$4" = "client" ]; then
		p2p_client
	fi
fi

#${IFNAME} CONNECTED
#${IFNAME} AP-STA-CONNECTED 2a:98:7b:d3:47:ed p2p_dev_addr=2a:98:7b:d3:c7:ed
if [ "$CMD" == "CONNECTED" ] || [ "$CMD" == "AP-STA-CONNECTED" ]; then
	touch /tmp/wpa_p2p_done
fi

#${IFNAME} AP-STA-DISCONNECTED 2a:98:7b:d3:47:ed p2p_dev_addr=2a:98:7b:d3:c7:ed
if [ "$CMD" == "AP-STA-DISCONNECTED" ]; then
	getP2PIF
	if [ "${P2PIF}" != "" ]; then
		WPA_CLI p2p_group_remove ${P2PIF}
	fi
	rm /tmp/wpa_p2p_done /tmp/wpa_last_event
#	WPA_CLI p2p_cancel
#	WPA_CLI p2p_stop_find
#	WPA_CLI p2p_find
fi

#${IFNAME} DISCONNECTED
if [ "$CMD" == "DISCONNECTED" ] || [ "$CMD" == "CTRL-EVENT-DISCONNECTED" ]; then
	p2p_reset
fi

#${IFNAME} P2P-GROUP-REMOVED wlan0 client reason=FORMATION_FAILED
#${IFNAME} P2P-DEVICE-LOST p2p_dev_addr=2a:98:7b:d3:c7:ed
if [ "$CMD" == "P2P-GROUP-REMOVED" ] || [ "$CMD" == "P2P-DEVICE-LOST" ]; then
	killall udhcpc hostapd dnsmasq 2>/dev/null
	WPA_CLI p2p_listen
fi

#${IFNAME} P2P-GO-NEG-REQUEST 2a:98:7b:d3:c7:ed dev_passwd_id=4
if [ "$CMD" == "P2P-GO-NEG-REQUEST" ]; then
	WPA_CLI p2p_connect ${3} pbc
fi

#${IFNAME} P2P-PROV-DISC-PBC-REQ 2a:98:7b:d3:c7:ed p2p_dev_addr=2a:98:7b:d3:c7:ed pri_dev_type=10-0050F204-5 name=Android_35a0 config_methods=0x80 dev_capab=0x27 group_capab=0x0
if [ "$CMD" == "P2P-PROV-DISC-PBC-REQ" ]; then
	if [ -e /sys/module/bcmdhd ]; then
		all_net=`ls /sys/class/net/`
		LOGGER "ls /sys/class/net/: ${all_net}"
		LOGGER "skip: ${WPA_CLI_ARG} wps_pbc any"
	else
		WPA_CLI wps_pbc any
	fi
fi

#${IFNAME} P2P-INVITATION-RECEIVED sa=2a:98:7b:d3:c7:ed go_dev_addr=2a:98:7b:d3:c7:ed bssid=2a:98:7b:d3:47:ed unknown-network
if [ "$CMD" == "P2P-INVITATION-RECEIVED" ]; then
	sa=`echo "${4}" | cut -d '=' -f 2`
	WPA_CLI p2p_connect ${sa} pbc
fi
