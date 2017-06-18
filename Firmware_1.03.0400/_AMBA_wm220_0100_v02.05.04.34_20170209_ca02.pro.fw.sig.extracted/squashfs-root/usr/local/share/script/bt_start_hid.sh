#!/bin/sh

if [ $# -eq 0 ] || [ "${1}" == "--help" ]; then
	echo "Usage1: $0 \"Name of BT Selfie Stick remote\""
	echo "for example connect to \"AB Shutter\" Selfie Stick remote by:"
	echo -e "\e[1;35m $0 \"AB Shutter\" \e[0m"
	echo "to run interactively, try"
	echo -e "\e[1;35m $0 \"AB Shutter\" x \e[0m"
	echo
	echo "Usage2: $0 \"MAC Address\" (support BLE only)"
	echo "for example connect to \"XiaoYi_RC\" Selfie Stick remote by:"
	echo -e "\e[1;35m $0 \"04:E6:76:AA:C5:F8\" \e[0m"
	exit 1
fi

CMD_LOGGER ()
{
	echo "$@"
	$@
}

BTCTL_FIFO_LOGGER ()
{
	echo "$@"
	sleep 0.1
	echo $@ > /tmp/bluetoothctl.fifo
}

#ble_quick_connect
#bluetoothctl_cmd
#blehid
cleanup()
{
	if [ "${ble_quick_connect}" == "" ]; then
		BTCTL_FIFO_LOGGER "quit"
		CMD_LOGGER rm -f /tmp/bluetoothctl.fifo
		CMD_LOGGER ${bluetoothctl_cmd}
	fi
	if [ "`ps -o args|grep /usr/libexec/bluetooth/bluetoothd|grep \"\-a\"|grep -v grep`" != "" ]; then
		CMD_LOGGER hciconfig hci0 leadv
		if [ "${blehid}" != "" ]; then
			echo -e "\e[1;35m warn: BT4.1 Concurrent Operation in BOTH Central and Peripheral \e[0m"
			echo -e "\e[1;35m       Are you sure not setting GATT_PERIPHERAL=no ? \e[0m"
		fi
	fi
}

#ia
interactive ()
{
	echo -n "continue? (Y/n): "
	if [ "${ia}" == "" ]; then
		yn=y
		echo "${yn}"
	else
		read yn
	fi
	if [ "${yn}" == "n" ]; then
		cleanup
		exit 1
	fi
}

#BT_MAC
start_hid ()
{
	if [ -e /dev/hidraw0 ]; then
		echo -e "\e[1;35m err: /dev/hidraw0 already connected \e[0m"
		cleanup
		exit 1
	fi

	##Pair
	echo -e "\e[1;35m Start Pairing \e[0m"
	BTCTL_FIFO_LOGGER "quit"
	sleep 0.1
	bluetoothctl -d -p 0000 -a NoInputNoOutput 2>/dev/null
	BTCTL_FIFO_LOGGER "trust ${BT_MAC}"
	sleep 1
	BTCTL_FIFO_LOGGER "pair ${BT_MAC}"
	n=0
	tmp=""
	while [ "${tmp}" == "" ] && [ $n -ne 5 ]; do
		n=$(($n + 1))
		sleep 1
		devices=`echo "paired-devices" | bluetoothctl 2>/dev/null | grep "^Device"`
		tmp=`echo "${devices}" | grep "${BT_MAC}"`
		echo "${devices}"
		echo -e "\e[1;35m\n ${tmp} \n\e[0m"
		interactive
	done

	if [ "${tmp}" == "" ]; then
		echo -e "\e[1;35m cannot pair ${BT_MAC} \e[0m"
		cleanup
		exit 1
	fi

	##Connect
	echo -e "\e[1;35m Start Connect \e[0m"
	sleep 1
	BTCTL_FIFO_LOGGER "connect ${BT_MAC}"
	n=0
	tmp=""
	while [ "${tmp}" == "" ] && [ $n -ne 5 ]; do
		n=$(($n + 1))
		sleep 1
		devices=`echo "info ${BT_MAC}" | bluetoothctl 2>/dev/null | grep -A 20 "^Device"`
		tmp=`echo "${devices}" | grep "Connected: yes"`
		echo "${devices}"
		echo -e "\e[1;35m\n ${tmp} \n\e[0m"
		interactive
	done

	if [ "${tmp}" == "" ]; then
		echo -e "\e[1;35m cannot connect ${BT_MAC} \e[0m"
		cleanup
		exit 1
	fi

	if [ -e /dev/hidraw0 ]; then
		echo -e "\e[1;35m\n /dev/hidraw0 will show your HID input \n\e[0m"
	fi

	echo -e "\e[1;35m\n Do not need to go through pairing process again next time \n\e[0m"
	echo -e "\e[1;35m\n Simply press device button to re-connect \n\e[0m"
}

#/tmp/cmd_done
#/tmp/gatttool_stdout
#/tmp/gatttool_stderr
fork_gatttool ()
{
	rm -f /tmp/cmd_done /tmp/gatttool_stdout /tmp/gatttool_stderr
	echo "$@"
	$@ > /tmp/gatttool_stdout 2>/tmp/gatttool_stderr
	echo -e "\e[1;35m\n`cat /tmp/gatttool_stdout` \n\e[0m"
	echo -e "\e[1;31m\n`cat /tmp/gatttool_stderr 2>/dev/null` \n\e[0m"
	sleep 0.5
	touch /tmp/cmd_done
}

wait_cmd_done ()
{
	w=0
	sleep 1
	while [ ! -e /tmp/cmd_done ] && [ $w -ne 10 ]; do
		w=$(($w + 1))
		sleep 1
	done
	if [ ! -e /tmp/cmd_done ]; then
		CMD_LOGGER killall gatttool
		echo -e "\e[1;35m ERR: ${BT_MAC} is not turned on ? \e[0m"
		cleanup
		exit 1
	fi
	interactive
}

#BT_MAC
start_blehid ()
{
	rm -f /tmp/cmd_done
	CMD_LOGGER killall gatttool
	if [ "`pidof gatttool`" != "" ]; then
		echo -e "\e[1;35m err: gatttool already started \e[0m"
		killall -9 gatttool
		cleanup
		exit 1
	fi

	#handle = 0x0036, uuid = 00002803-0000-1000-8000-00805f9b34fb
	#handle = 0x0037, uuid = 00002a4d-0000-1000-8000-00805f9b34fb
	#handle = 0x0038, uuid = 00002908-0000-1000-8000-00805f9b34fb
	#handle = 0x0039, uuid = 00002902-0000-1000-8000-00805f9b34fb
	fork_gatttool gatttool -b ${BT_MAC} --char-desc &
	wait_cmd_done
	stage=0
	while read tmp; do
		if [ ${stage} -eq 0 ]; then
			rr=`echo "${tmp}"|grep 2a4d`
			if [ "${rr}" != "" ]; then
				echo "0x2a4d Report found"
				#stage 1: looking for 0x2902 CCC
				stage=1
				continue
			fi
		elif [ ${stage} -eq 1 ]; then
			tc=`echo "${tmp}"|grep 2902`
			if [ "${tc}" != "" ]; then
				echo "0x2902 Client Characteristic Configuration found"
				hh=`echo "${tmp}"|cut -d ',' -f 1|awk '{print $3}'`
				ccc_all="${ccc_all} ${hh}"
				#stage 0: looking for 0x2a4d Report
				stage=0
				continue
			fi
		fi
	done < 	/tmp/gatttool_stdout

	if [ "${ccc_all}" == "" ]; then
		echo -e "\e[1;35m ERR: Cannot find 0x2902 Client Characteristic Configuration \e[0m"
		cleanup
		exit 1
	fi

	#Characteristic value was written successfully
	#connect: Device or resource busy (16)
	#Characteristic Write Request failed: Internal application error: I/O
	for ccc in $ccc_all; do
		fork_gatttool gatttool -b ${BT_MAC} --char-write-req --handle=${ccc} --value=01 &
		wait_cmd_done
		n=0
		ee=`cat /tmp/gatttool_stderr 2>/dev/null`
		while [ "${ee}" != "" ] && [ $n -ne 10 ]; do
			echo -e "\e[1;35m BUGGY Selfie: Press Selfie any button now! \e[0m"
			n=$(($n + 1))
			CMD_LOGGER sleep $n
			fork_gatttool gatttool -b ${BT_MAC} --char-write-req --handle=${ccc} --value=01 &
			wait_cmd_done
			ee=`cat /tmp/gatttool_stderr 2>/dev/null`
			echo -e "\e[1;31m [${ee}] \e[0m"
		done

		if [ "${ee}" != "" ]; then
			echo -e "\e[1;35m notification cannot be enabled \e[0m"
			cache_cmd=no
		fi
	done

	# BUGGY Selfie: read wrong ccc value
	#hid_gatt_cmd="gatttool -b ${BT_MAC} --char-read --handle=${ccc} --listen --amba"
	hid_gatt_cmd="gatttool -b ${BT_MAC} --char-write-req --handle=${ccc} --value=01 --listen --amba"
	if [ "${cache_cmd}" == "no" ]; then
		rm -f /tmp/hid_gatt_disconnect_cb.sh
	else
		echo ${hid_gatt_cmd} > /tmp/hid_gatt_disconnect_cb.sh
		chmod 777 /tmp/hid_gatt_disconnect_cb.sh
	fi

	${hid_gatt_cmd}

	if [ "${ble_quick_connect}" == "" ]; then
		echo -e "\e[1;35m\n To recover connection after reboot: \e[0m"
		echo -e "\e[1;35m\n  1. turned on BLE remote\e[0m"
		echo -e "\e[1;35m\n  2. ${0} ${BT_MAC} \n\e[0m"
	fi
}

##### main
if [ "`ps -o args|grep /usr/libexec/bluetooth/bluetoothd|grep -v grep`" == "" ]; then
	echo -e "\e[1;35m err: bluetoothd not started \e[0m"
	exit 1
fi

if [ -p /tmp/bluetoothctl.fifo ]; then
	echo -e "\e[1;35m err: /tmp/bluetoothctl.fifo exits \e[0m"
	CMD_LOGGER killall -9 bluetoothctl
	CMD_LOGGER rm -f /tmp/bluetoothctl.fifo
	exit 1
fi

#bluetoothctl_cmd: restart bluetoothctl at cleanup
bluetoothctl_cmd=`ps -o args|grep bluetoothctl|grep -v grep`
if [ "${bluetoothctl_cmd}" == "" ]; then
	echo -e "\e[1;35m err: bluetoothctl not started \e[0m"
	exit 1
fi

#ia: interactive
if [ $# -gt 1 ]; then
	ia=1
fi

CMD_LOGGER hciconfig hci0 noleadv

#shortcut
if [ "`echo ${1}|grep :|wc -c`" == "18" ] ; then
	if [ "`grep ${1} /tmp/hid_gatt_disconnect_cb.sh`" != "" ] ; then
		/tmp/hid_gatt_disconnect_cb.sh
		exit $?
	fi
	ble_quick_connect=1
	BT_MAC=${1}
	start_blehid
	if [ "`ps -o args|grep /usr/libexec/bluetooth/bluetoothd|grep \"\-a\"|grep -v grep`" != "" ]; then
		CMD_LOGGER hciconfig hci0 leadv
		echo -e "\e[1;35m warn: BT4.1 Concurrent Operation in BOTH Central and Peripheral \e[0m"
		echo -e "\e[1;35m       Are you sure not setting GATT_PERIPHERAL=no ? \e[0m"
	fi
	exit 0
fi

##restart bluetoothctl
CMD_LOGGER killall bluetoothctl
if [ "`ps -o args|grep bluetoothctl|grep -v grep`" != "" ]; then
	CMD_LOGGER killall -9 bluetoothctl
fi

CMD_LOGGER mkfifo /tmp/bluetoothctl.fifo -m 666
devices=`echo "devices" | bluetoothctl 2>/dev/null | grep "^Device"`
BT_MAC=`echo "${devices}" | grep "${1}" | head -n 1 | awk '{print $2}'`

trap cleanup INT TERM

##Scan for BT_MAC
echo -e "\e[1;35m Start Scan \e[0m"
CMD_LOGGER bluetoothctl -d 2>/dev/null
if [ "${BT_MAC}" != "" ]; then
	BTCTL_FIFO_LOGGER "remove ${BT_MAC}"
fi

BTCTL_FIFO_LOGGER "scan on"

n=0
tmp=""
while [ "${tmp}" == "" ] && [ $n -ne 15 ]; do
	n=$(($n + 1))
	sleep 1
	devices=`echo "devices" | bluetoothctl 2>/dev/null | grep "^Device"`
	tmp=`echo "${devices}" | grep "${1}" | head -n 1`
	echo "${devices}"
	echo -e "\e[1;35m\n ${tmp} \n\e[0m"
	interactive
done
BTCTL_FIFO_LOGGER "scan off"
if [ "${tmp}" == "" ]; then
	echo -e "\e[1;35m cannot find ${1} \e[0m"
	cleanup
	exit 1
fi
BT_MAC=`echo "${tmp}" | awk '{print $2}'`

#wait device available for pairing
n=0
tmp=""
while [ "${tmp}" == "" ] && [ $n -ne 15 ]; do
	n=$(($n + 1))
	sleep 1
	devices=`echo "info ${BT_MAC}" | bluetoothctl 2>/dev/null | grep -v "not available"`
	tmp=`echo "${devices}"|grep "input-keyboard"`
	echo "${devices}"
	echo -e "\e[1;35m\n `echo \"${devices}\" | grep -A 20 \"^Device\"` \n\e[0m"
	interactive
done

blehid=`echo "${devices}" | grep "00001812"`
if [ "${blehid}" != "" ]; then
	start_blehid
else
	start_hid
fi

cleanup
echo ${BT_MAC} > /tmp/BT_MAC
exit 0
