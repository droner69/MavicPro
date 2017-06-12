#!/system/bin/sh
BOARD_ID=(0xe2200017 0xe2200025 0xe2200018 0xe2200026 0xe2200042 0xe2200051)
WL_MODE=SDR

#judge this is power on or reboot or panic
# power on :1, reboot 0
function is_hot_reset()
{
#check reboot reason
	reboot_reason=`cat /sys/bootinfo/reboot_reason | busybox awk '/Active/{print $1}'`
	echo reboot caused by $reboot_reason
	if [ $reboot_reason != "null" ]; then
		return 1
	fi
#checkout whether it is kernel panic
	panic_reboot=$((`busybox devmem 0xE007FF40 8`))
	echo ap panic reboot flag $panic_reboot
	if [ $panic_reboot -ne 0 ]; then
		return 1
	fi
	return 0

}

#judge whether board support wifi/sdr hw switch V6s/V7A/V7S/V8S
# support 1, non-support 0
function is_switch_support_board()
{
	hw_switch_support=0
	echo "get board id"
	boardid=`cat /proc/cmdline | busybox awk '{for(a=1;a<=NF;a++) print $a}' | busybox grep board_id | busybox awk -F '=' '{print $2}'`
	echo boardid is $boardid
	for id in ${BOARD_ID[*]}; do
		if [ $boardid = $id ]; then
			echo "board support wifi sdr switch"
			hw_switch_support=1
		fi
	done
	return $hw_switch_support
}

#read GPIP and judge whether wifi is enabled
# return 0 judge sussfully 1 cann't judge
function is_sdr_enabled()
{
	sdr_enable=1
	echo 199 > /sys/class/gpio/export
	if [ -r /sys/class/gpio/gpio199/value ]; then
		echo "gpio value is ready"
	else
		echo "error gpio value could not be read"
		return 1
	fi
	level=`cat /sys/class/gpio/gpio199/value`
	if [ $level -eq 0 ]; then
		sdr_enable=0
	fi
	return $sdr_enable
}

#for auto test
if [ -f "data/dji/cfg/wifi_enable" ]; then
	return 0
elif [ -f "data/dji/cfg/sdr_enable" ]; then
	return 1
fi

is_hot_reset
if [ $? -eq 1 ]; then
	if [ -r /data/wl_link.cfg ]; then
		mode_for_last=`cat /data/wl_link.cfg`
		if [ $mode_for_last = "SDR" ]; then
			/system/bin/antenna_switch.sh SDR
			echo "reboot used for last mode SDR"
			exit 1
		elif [ $mode_for_last = "WIFI" ]; then
			/system/bin/antenna_switch.sh WIFI
			echo "reboot used for last mode WIFI"
			exit 0
		fi
	fi
fi

is_switch_support_board
if [ $? -eq 0 ]; then
#old board not support hw switch
	echo SDR > /data/wl_link.cfg
	/system/bin/antenna_switch.sh SDR
	echo "legency board only sdr support"
	exit 1
else
	echo "hw switch supported"
fi

is_sdr_enabled
if [ $? -eq 1 ]; then
	echo SDR > /data/wl_link.cfg
	/system/bin/antenna_switch.sh SDR
	echo "hw switch on SDR mode"
	exit 1
else
	echo WIFI > /data/wl_link.cfg
	/system/bin/antenna_switch.sh WIFI
	echo "hw switch on WIFI mode"
	exit 0
fi
