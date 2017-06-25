#!/bin/sh

LOGGER ()
{
	if [ "${sysl}" != "" ]; then
		logger "${b0}:${@}"
	else
		echo "$@"
	fi
}

#Do not save conf to SD card
#SYNC_CONIG ()
#{
#	checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
#	if [ "${checkfuse}" == "" ]; then
#		fuse_d="/tmp/SD0"
#	else
#		fuse_d="/tmp/fuse_d"
#	fi
#	#tmp -> pref, misc
#	if [ -e /tmp/lte.conf ]; then
#		LOGGER "==> Load lte.conf from /tmp ..."
#		lteconf=`cat /tmp/lte.conf | sed -e 's/\r$//'`
#		echo "${lteconf}" > /pref/lte.conf
#	elif [ ! -e /pref/lte.conf ]; then
#		cp /usr/local/share/script/lte.conf /pref/lte.conf
#	fi
#}

SYNC_CONIG ()
{
	checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
	if [ "${checkfuse}" == "" ]; then
		fuse_d="/tmp/SD0"
	else
		fuse_d="/tmp/fuse_d"
	fi
	#tmp -> pref, misc
	if [ -e /tmp/lte.conf ]; then
		LOGGER "==> Load lte.conf from /tmp ..."
		lteconf=`cat /tmp/lte.conf | sed -e 's/\r$//'`
		echo "${lteconf}" > /pref/lte.conf
		lteconf=`cat /pref/lte.conf | sed -e 's/$/\r/'`
		echo "${lteconf}" > ${fuse_d}/MISC/lte.conf
	#misc -> pref
	elif [ -e ${fuse_d}/MISC/lte.conf ]; then
		LOGGER "==> Load lte.conf from SD/MISC..."
		lteconf=`cat ${fuse_d}/MISC/lte.conf | sed -e 's/\r$//'`
		echo "${lteconf}" > /pref/lte.conf
	#pref -> misc
	elif [ -e /pref/lte.conf ]; then
		mkdir -p ${fuse_d}/MISC
		lteconf=`cat /pref/lte.conf | sed -e 's/$/\r/'`
		echo "${lteconf}" > ${fuse_d}/MISC/lte.conf
	#fw -> pref, misc
	elif [ -e /usr/local/share/script/lte.conf ]; then
		cp /usr/local/share/script/lte.conf /pref/lte.conf
		mkdir -p ${fuse_d}/MISC
		lteconf=`cat /pref/lte.conf | sed -e 's/$/\r/'`
		echo "${lteconf}" > ${fuse_d}/MISC/lte.conf
	fi
}

reset_conf ()
{
	echo "reset lte.conf"
	cp /usr/local/share/script/lte.conf /pref/lte.conf
	lteconf=`cat /pref/lte.conf | sed -e 's/$/\r/'`
	echo "${lteconf}" > ${fuse_d}/MISC/lte.conf
}

dns_nodns ()
{
	dhcp_range=`ps|grep -v grep|grep dnsmasq|grep queries|awk '{print $NF}'`
	if [ "${dhcp_range}" != "" ]; then
		killall dnsmasq; sleep 0.1
		LOGGER "dnsmasq --nodns -5 -K -R -n ${dhcp_range}"
		dnsmasq --nodns -5 -K -R -n ${dhcp_range}
	fi
}

dns_queries ()
{
	dhcp_range=`ps|grep -v grep|grep dnsmasq|grep nodns|awk '{print $NF}'`
	if [ "${dhcp_range}" != "" ]; then
		killall dnsmasq; sleep 0.1
		LOGGER "dnsmasq -5 -K --log-queries ${dhcp_range}"
		dnsmasq -5 -K --log-queries ${dhcp_range}
	fi
}

do_lte_router ()
{
	enabled=`iptables -t nat -n -L|grep MASQUERADE`
	if [ "${enabled}" == "" ]; then
		LOGGER "echo 1 > /proc/sys/net/ipv4/ip_forward"
		echo 1 > /proc/sys/net/ipv4/ip_forward
		LOGGER "iptables -t nat -A POSTROUTING -o ${forwardif} -j MASQUERADE"
		iptables -t nat -A POSTROUTING -o ${forwardif} -j MASQUERADE
	fi

	dns_queries
}

lte_stop ()
{
	#ppp
	LOGGER "killall pppd"
	killall pppd 2>/dev/null
	dns_nodns

	#qmi
	load_qmi_state
	if [ "${CID}" != "" ] && [ "${PDH}" != "" ]; then
		LOGGER "qmicli -d /dev/cdc-wdm0 --wds-stop-network=${PDH} --client-cid=${CID}"
		stop_net=`qmicli -d /dev/cdc-wdm0 --wds-stop-network=${PDH} --client-cid=${CID} 2>&1`
	else
		if [ "${CID}" != "" ]; then
			LOGGER "qmicli -d /dev/cdc-wdm0 --wds-noop --client-cid=${CID}"
			stop_net=`qmicli -d /dev/cdc-wdm0 --wds-noop --client-cid=${CID} 2>&1`
		fi
	fi
	LOGGER "${stop_net}"
	kill `ps|grep udhcpc|grep wwan0|grep -v grep|awk '{print $1}'` 2>/dev/null
	ifconfig wwan0 down
	rm -f /tmp/qmi_state

	vidpid=`grep "Vendor=" /sys/kernel/debug/usb/devices|grep -v "Vendor=1d6b"|awk '{print $2,$3}'`
	if [ "${vidpid}" != "" ]; then
		eval `echo "${vidpid}"`
		net=`find /sys/devices/*ahb/*ehci/usb*/ -name net|tail -n 1`
		if [ "${net}" != "" ]; then
			forwardif=`ls ${net}`

			#altair
			if [ "${Vendor}" == "216f" ]; then
				echo -e "ATE0\r" > /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				echo -e "AT+CGATT=0\r" >> /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				microcom -s 115200 -t 1000 /dev/ttyACM0 < /tmp/at_in > /tmp/at_out
				LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
			#Sequans
			elif [ "${Vendor}" == "258d" ]; then
				echo -e "ATE0\r" > /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				echo -e "AT+CFUN=4\r" >> /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				microcom -s 115200 -t 1000 /dev/ttyACM0 < /tmp/at_in > /tmp/at_out
				LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
			fi
			if [ "${forwardif}" != "" ]; then
				kill `ps|grep udhcpc|grep ${forwardif}|grep -v grep|awk '{print $1}'`
				ifconfig ${forwardif} down
			else
				LOGGER "err: find ${net}"
			fi
		fi
	fi

	#spawns_myself
	killall lte_start.sh
}

save_qmi_state ()
{
	KEY=$1
	VAL=$2

	if [ -f /tmp/qmi_state ]; then
		oldstat=`cat /tmp/qmi_state | grep -v $KEY`
		if [ "$oldstat" != "" ]; then
			echo $oldstat > /tmp/qmi_state
		else
			rm /tmp/qmi_state
		fi
	fi

	echo "$KEY=\"$VAL\"" >> /tmp/qmi_state
}

#CID, PDH
load_qmi_state ()
{
	if [ -f /tmp/qmi_state ]; then
		. /tmp/qmi_state
	fi
}

spawns_myself ()
{
	LOGGER "Spawns another instance of this same script, do not block S10mdev"
	sleep 3
	/usr/local/share/script/lte_start.sh
}

#simcom sim5360: 05c6 9000
#telit le910: 1bc7 1201
#wnc d18q1: 1435 d181
#LS u8300w: 1c9e 9b05
#Altair: 216f 0047
#Sequans: 258d 2000
#u-blox:1546 1146
auto_setting()
{
	if [ ! -e /sys/kernel/debug/usb/devices ]; then
		spawns_myself &
		exit 0
	fi
	vidpid=`grep "Vendor=" /sys/kernel/debug/usb/devices|grep -v "Vendor=1d6b"|awk '{print $2,$3}'`
	if [ "${vidpid}" != "" ]; then
		eval `echo "${vidpid}"`
	else
		LOGGER "err: cannot get Vendor ProdID from /sys/kernel/debug/usb/devices"
		exit 1
	fi

	#API
	if [ "${API}" == "" ]; then
		case ${Vendor} in
		05c6)
			LOGGER "SIMCOM: using libqmi"
			API="QMI"
		;;
		1bc7)
			LOGGER "Telit: using libqmi"
			API="QMI"
		;;
		1435)
			LOGGER "WNC found"
			LOGGER "WARNING: please find WNC to get MAL SDK: /usr/local/mal/malmanager -c /tmp/malmanager.cfg"
			API="QMI"
		;;
		1c9e)
			LOGGER "LongSung found"
			LOGGER "WARNING: please find LongSung to get ndis SDK: ndis_manager -c"
			API="QMI"
		;;
		216f)
			LOGGER "Altair found"
			API="ALTAIR"
		;;
		258d)
			LOGGER "Sequans found"
			API="SEQUANS"
		;;
		1546)
			LOGGER "UBLOX found"
			API="UBLOX"
		;;
		*)
			LOGGER "default: API=AT"
			API="AT"
		;;
		esac
	fi
	if [ "${API}" == "QMI" ] && [ ! -e /dev/cdc-wdm0 ]; then
		echo ${Vendor} ${ProdID} > /sys/bus/usb/drivers/qmi_wwan/new_id
		LOGGER "echo ${Vendor} ${ProdID} > /sys/bus/usb/drivers/qmi_wwan/new_id"; sleep 0.1
	fi

	#UART_NODE
	if [ "${UART_NODE}" == "" ]; then
		case ${Vendor} in
		05c6)
			LOGGER "SIMCOM: UART_NODE=/dev/ttyUSB3"
			UART_NODE=/dev/ttyUSB3
		;;
		1bc7)
			LOGGER "Telit: UART_NODE=/dev/ttyUSB2"
			UART_NODE=/dev/ttyUSB2
		;;
		1435)
			LOGGER "WNC: UART_NODE=/dev/ttyUSB1"
			UART_NODE=/dev/ttyUSB1
		;;
		1c9e)
			LOGGER "LongSung: UART_NODE=/dev/ttyUSB1"
			UART_NODE=/dev/ttyUSB1
		;;
		216f)
			LOGGER "Altair: UART_NODE=/dev/ttyACM0"
			UART_NODE=/dev/ttyACM0
		;;
		258d)
			LOGGER "Sequans: UART_NODE=/dev/ttyACM0"
			UART_NODE=/dev/ttyACM0
		;;
		1546)
			LOGGER "UBLOX: UART_NODE=/dev/ttyACM0"
			UART_NODE=/dev/ttyACM0
		;;
		*)
			LOGGER "default: UART_NODE=/dev/ttyUSB1"
			UART_NODE=/dev/ttyUSB1
		;;
		esac
	fi
	if [ ! -e ${UART_NODE} ]; then
		LOGGER "${UART_NODE} not found"
		exit 0
	fi

	#sometimes hotplug event comes too early
	wait_usbnet

	if [ "${APN}" == "" ]; then
		#PIN
		if [ "${SIM_PIN}" != "" ]; then
			echo -e "ATE0\r" > /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			if [ "${SIM_PIN}" != "" ]; then
				echo -e "AT+CPIN=${SIM_PIN}\r" >> /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
			fi
			microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
			LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		fi

		if [ "${API}" == "ALTAIR" ]; then
			echo -e "ATE0\r" > /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CFUN=1,0\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CGATT=1\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
			LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		elif [ "${API}" == "SEQUANS" ]; then
			echo -e "ATE0\r" > /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CFUN=1\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
			LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		fi

		#CIMI
		echo -e "ATE0\r" > /tmp/at_in
		echo -e "AT\r" >> /tmp/at_in
		echo -e "AT#CIMI\r" >> /tmp/at_in
		echo -e "AT\r" >> /tmp/at_in
		microcom -s 115200 -t 2000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
		LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		MCC=`grep "#CIMI:" /tmp/at_out|awk '{print $2}'|cut -c 1-3`
		MNC=`grep "#CIMI:"  /tmp/at_out|awk '{print $2}'|cut -c 4-5`

		if [ "${MCC}" == "" ] || [ "${MNC}" == "" ]; then
			LOGGER "AT#CIMI not supported, try AT+COPS?"
			n=0
			while [ "${MCC}" == "" ] && [ $n -ne 5 ]; do
				LOGGER "[trial $n]"
				echo -e "ATE0\r" > /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				echo -e "AT+COPS=3,2\r" >> /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				echo -e "AT+COPS?\r" >> /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
				LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
				MCC=`grep "+COPS:" /tmp/at_out|cut -d ',' -f 3|sed -e 's/"//g'|cut -c 1-3|grep -E "^[0-9]+$"`
				MNC=`grep "+COPS:" /tmp/at_out|cut -d ',' -f 3|sed -e 's/"//g'|cut -c 4-5|grep -E "^[0-9]+$"`
				n=$(($n + 1))
			done
		fi
		if [ "${MCC}" == "" ] || [ "${MNC}" == "" ]; then
			LOGGER "err: cannot get MCC and MNC, add into /usr/local/share/script/autoapn.txt"
		else
			#APN
			dbid=`printf "%d|%d|\n" ${MCC#0} ${MNC#0}`
			APN=`grep $dbid /usr/local/share/script/autoapn.txt| grep -Ev "^#" |cut -d '|' -f 3`
			unlock_pin="AT OK"
		fi
	else
		if [ "${API}" == "QMI" ]; then
			#PIN
			if [ "${SIM_PIN}" != "" ]; then
				echo -e "ATE0\r" > /tmp/at_in
				echo -e "AT\r" >> /tmp/at_in
				if [ "${SIM_PIN}" != "" ]; then
					echo -e "AT+CPIN=${SIM_PIN}\r" >> /tmp/at_in
					echo -e "AT\r" >> /tmp/at_in
				fi
				microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
				LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
			fi
		elif [ "${API}" == "ALTAIR" ]; then
			echo -e "ATE0\r" > /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CFUN=1,0\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CGATT=1\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
			LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		elif [ "${API}" == "SEQUANS" ]; then
			echo -e "ATE0\r" > /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			echo -e "AT+CFUN=1\r" >> /tmp/at_in
			echo -e "AT\r" >> /tmp/at_in
			microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
			LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		else
			if [ "${SIM_PIN}" != "" ]; then
				unlock_pin="AT+CPIN=${SIM_PIN} ERROR-AT-OK AT OK"
			else
				unlock_pin="AT OK"
			fi
		fi
	fi
	LOGGER "MCC=${MCC} MNC=${MNC} APN=${APN}"
	if [ "${APN}" == "" ]; then
		LOGGER "err: APN (Access Point Name) is not configured, add ${MCC#0} ${MNC#0} into /usr/local/share/script/autoapn.txt"
		at_apn="AT+CGDCONT=1,\"IP\" OK"
	else
		at_apn="AT+CGDCONT=1,\"IP\",\"${APN}\" OK"
	fi
}

start_at_cmd ()
{
	chatscript="\
	TIMEOUT 5 \
	ABORT 'DELAYED' \
	ABORT 'BUSY' \
	ABORT 'ERROR' \
	ABORT 'NO DIALTONE' \
	ABORT 'NO CARRIER' \
	'' \
	AT OK \
	${unlock_pin} \
	${at_apn} \
	AT OK \
	ATE0V1 OK \
	AT OK \
	ATS0=0 OK \
	AT OK \
	ATE0V1 OK \
	AT OK \
	ATD*99# CONNECT \
	"

	echo "${chatscript}" > /tmp/pppd.conf
	LOGGER "`cat /tmp/pppd.conf`"

	pppd ${UART_NODE} defaultroute persist usepeerdns connect "chat -v -f /tmp/pppd.conf"

	forwardif=ppp0
}

wait_usbnet ()
{
	#ALTAIR, UBLOX, SEQUANS
	if [ "${Vendor}" == "216f" ] || [ "${Vendor}" == "1546" ] || [ "${Vendor}" == "258d" ]; then
		net=`find /sys/devices/*ahb/*ehci/usb*/ -name net|tail -n 1`
		n=0
		while [ "${net}" == "" ]; do
			LOGGER "${n} sleep 1"
			sleep 1
			n=$(($n + 1))
			net=`find /sys/devices/*ahb/*ehci/usb*/ -name net|tail -n 1`
		done
		forwardif=`ls ${net}`
		LOGGER "found ${forwardif}"
	fi
}

start_usbnet ()
{
	#must have registered home network before connect
	n=0
	while [ "${MCC}" == "" ]; do
		LOGGER "[trial $n]"
		echo -e "ATE0\r" > /tmp/at_in
		echo -e "AT\r" >> /tmp/at_in
		echo -e "AT+COPS=3,2\r" >> /tmp/at_in
		echo -e "AT\r" >> /tmp/at_in
		echo -e "AT+COPS?\r" >> /tmp/at_in
		echo -e "AT\r" >> /tmp/at_in
		microcom -s 115200 -t 1000 ${UART_NODE} < /tmp/at_in > /tmp/at_out
		LOGGER "`cat /tmp/at_in`"; LOGGER "`cat /tmp/at_out`"
		MCC=`grep "+COPS:" /tmp/at_out|cut -d ',' -f 3|sed -e 's/"//g'|cut -c 1-3|grep -E "^[0-9]+$"`
		MNC=`grep "+COPS:" /tmp/at_out|cut -d ',' -f 3|sed -e 's/"//g'|cut -c 4-5|grep -E "^[0-9]+$"`
		n=$(($n + 1))
	done

	net=`find /sys/devices/*ahb/*ehci/usb*/ -name net|tail -n 1`
	forwardif=`ls ${net}`

	udhcpc -i ${forwardif} -A 1

	#Sequans 192.168.15.x means network not ready
	#Altair	 10.0.0.x means network not ready
	n=0
	IP=`ifconfig ${forwardif}|grep -E "(:10.0.0.|:192.168.15.)"`
	while [ "${IP}" != "" ]; do
		kill `ps|grep udhcpc|grep ${forwardif}|grep -v grep|awk '{print $1}'`
		IP=`ifconfig ${forwardif}|grep -E "(:10.0.0.|:192.168.15.)"`
		LOGGER "$n IP=${IP}"
		n=$(($n + 1))
		sleep 1
		udhcpc -i ${forwardif} -A 1
	done
}

start_libqmi ()
{
	QMI_NODE=`ls /dev/cdc-wdm*|head -n 1`
	if [ ! -e ${QMI_NODE} ]; then
		LOGGER "err: /dev/cdc-wdm* not found"
		exit 1
	fi

	#must have registered home network before connect
	homelog=`qmicli -d /dev/cdc-wdm0 --nas-get-home-network`
	homeready=$?
	LOGGER "${homelog}"
	n=0
	while [ ${homeready} -ne 0 ]; do
		homelog=`qmicli -d /dev/cdc-wdm0 --nas-get-home-network 2>&1`
		homeready=$?
		LOGGER "${n}:${homelog}"
		sleep 1
		n=$(($n + 1))
	done

	#connect
	LOGGER "qmicli -d ${QMI_NODE} --wds-start-network=${APN} --client-no-release-cid"
	start_net=`qmicli -d ${QMI_NODE} --wds-start-network=${APN} --client-no-release-cid 2>&1`
	start_return=$?
	LOGGER "${start_return} ${start_net}"
	CID=`echo "$start_net" | sed -n "s/.*CID.*'\(.*\)'.*/\1/p"`
	PDH=`echo "$start_net" | sed -n "s/.*handle.*'\(.*\)'.*/\1/p"`

	n=1
	#while [ "${CID}" == "" ] || [ "${PDH}" == "" ]; do
	while [ ${start_return} -ne 0 ]; do
		LOGGER "sleep ${n}"
		sleep $n
		n=$(($n + 1))
		LOGGER "qmicli -d ${QMI_NODE} --wds-start-network=${APN} --client-no-release-cid"
		start_net=`qmicli -d ${QMI_NODE} --wds-start-network=${APN} --client-no-release-cid 2>&1`
		start_return=$?
		LOGGER "${start_return} ${start_net}"
		CID=`echo "$start_net" | sed -n "s/.*CID.*'\(.*\)'.*/\1/p"`
		PDH=`echo "$start_net" | sed -n "s/.*handle.*'\(.*\)'.*/\1/p"`
	done

	save_qmi_state "CID" $CID
	save_qmi_state "PDH" $PDH

	udhcpc -i wwan0 -A 1 -b

	forwardif=wwan0
}
##### main ##########################################

sysl=`ps | grep syslogd | grep -v grep`
b0=`basename ${0}`

if [ "${b0}" == "lte_stop.sh" ]; then
	lte_stop
	exit 0
fi

if [ "$ACTION" != "" ]; then
	LOGGER ${ACTION}
	if [ "$SUBSYSTEM" != "tty" ]; then
		LOGGER "exit to prevent multiple call from mdev"
		exit 0
	fi

	if [ "$ACTION" == "remove" ]; then
		lte_stop
		exit 0
	fi
else
	LOGGER "WARNING: Must run in background, blocking script until LTE ready"
fi

pidof pppd && exit 0

SYNC_CONIG
if [ -e /pref/lte.conf ]; then
	lte_conf=`cat /pref/lte.conf | grep -Ev "^#"`
	export `echo "${lte_conf}"|grep -vI $'^\xEF\xBB\xBF'`
fi

auto_setting

if [ "${API}" == "QMI" ]; then
	start_libqmi
elif [ "${API}" == "AT" ]; then
	start_at_cmd
else
	start_usbnet
fi

do_lte_router

#enable auto power control
if [ -e /sys/bus/usb/devices/1-1/power/control ]; then
	echo auto > /sys/bus/usb/devices/1-1/power/control
else
	LOGGER "err: no power saving"
fi

#customer hook script
if [ -e ${fuse_d}/MISC/lte_hook.sh ]; then
	${fuse_d}/MISC/lte_hook.sh
fi
