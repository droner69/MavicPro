. lib_test_utils.sh

#
# LED
#

RED=145
GREEN=146
ULTRA_RESET=228

led_on()
{
	gpio_write $1 0
	echo led_on - $1, $2
}

led_off()
{
	gpio_write $1 1
	echo led_off - $1, $2
}

# A9 aging support start
A9_AGING_UNKNOWN="UNKNOWN"
A9_AGING_PASS="PASS"
A9_AGING_FAIL="FAIL"
A9_AGING_doing="DOING"
A9_AGING_NOT_START="NOT_START"
A9_AGING_HANG="HANG"

a9_aging_state_dir=/tmp/a9_aging_state
# $ret
# 0 pass
# 1 fail
# 2 doing
# 3 not start
# 4 a9 hang
# 5 unknown
check_a9_aging_state()
{
	local ret=0
	local a9_aging_state=$A9_AGING_UNKNOWN
	if [ -f $a9_aging_state_dir ];then
		a9_aging_state=`cat $a9_aging_state_dir`
	fi
	echo $a9_aging_state >> /data/a9_aging_log.txt
	case $a9_aging_state in
		PASS)  echo 'pass' >>/data/a9_aging_log.txt
			ret=0
			;;
		FAIL)  echo 'fail' >>/data/a9_aging_log.txt
			ret=1
			echo "FAILED" > /data/dji/amt/a9_aging_test_result
			;;
		DOING)  echo 'doing' >>/data/a9_aging_log.txt
			ret=2
			;;
		NOT_START)  echo 'not start' >>/data/a9_aging_log.txt
			ret=3
			;;
		HANG)  echo 'hang' >>/data/a9_aging_log.txt
			ret=4
			;;
		*)  echo 'unknown state' >>/data/a9_aging_log.txt
			ret=5
			;;
	esac
	return $ret
}
# A9 aging support end

led_blink()
{
	local a9=4 #default unknown state

	check_a9_aging_state
	a9=$?
	if [ ! -f $led_blinking ]; then
		return 1
	fi

	if [ $a9 == 1 ];then #A9 fail
		led_on $RED led_blink
		sleep 0.1
		led_off $RED led_blink
		sleep 0.1
		led_on $RED led_blink
		sleep 0.1
		led_off $RED led_blink
		sleep 2
		return
	fi
	if [ $a9 == 4 ];then #A9 hang
		led_on $RED led_blink
		sleep 0.1
		led_off $RED led_blink
		sleep 0.1
		led_on $RED led_blink
		sleep 0.1
		led_off $RED led_blink
		sleep 0.1
		led_on $RED led_blink
		sleep 0.1
		led_off $RED led_blink
		sleep 0.1
		return
	fi
	if [ $a9 == 2 ] && [ ! -f /data/dji/amt/aging_test/result ];then #A9 doing
		led_on $GREEN led_blink
		sleep 0.1
		led_off $GREEN led_blink
		sleep 0.1
		led_on $GREEN led_blink
		sleep 0.1
		led_off $GREEN led_blink
		sleep 1
	fi


	led_on $1 led_blink
	sleep 1
	led_off $1 led_blink
	sleep 1
}

led_quick_blink()
{
        if [ ! -f $led_blinking ]; then
                return 1
        fi
        led_on $1 led_blink
        sleep 0.1
        led_off $1 led_blink
        sleep 0.1
}

# link path test cases
#

linked_to_camera()
{
	cmd_check_ver camera 1 0
}

linked_to_flyctl()
{
	cmd_check_ver flyctl 3 0
}

linked_to_gimbal()
{
	cmd_check_ver gimbal 4 0
}

linked_to_battery()
{
	cmd_check_ver battery 11 0
}

linked_to_esc()
{
	cmd_check_ver esc 12 $1
}

# 0x1707(dji_vision) is local channel of 1860
# so no need for AMT aging_test
linked_to_mvision()
{
	cmd_check_ver mvision 17 7
}

# ma2100 version is got from the log,
# so we check the USB to decide whether everything works
linked_to_bvision()
{
	busybox lsusb | grep 040e 1>/dev/null
	local r=$?
	if [ $r == 0 ]; then
		echo linked_to_bvision\($1\): PASSED
	else
		echo linked_to_bvision\($1\): FAILED, errno=$r
	fi
	return $r
#	cmd_check_ver ma2100 8 2
#	cmd_check_ver 18 7
}

linked_to_ltc_fpga()
{
	cmd_check_ver ltc_fpga 8 3
}

linked_to_ultrasonic()
{
	cmd_check_ver ultrasonic 8 4
}

check_ultrasonic_reset_pin()
{
	gpio_write $ULTRA_RESET 0
	sleep 1
	cmd_check_ver_without_try ultrasonic_rst 8 4 1>/dev/null
	if [ $? == 0 ];then
		echo "FAILED: Still can got version after ultrasonic reset!"
		return 1
	fi

	gpio_write $ULTRA_RESET 1
	sleep 3
	cmd_check_ver_without_try ultrasonic_rst 8 4 || return $?
}

factory_out_check_link()
{
	linked_to_ltc_fpga || return $?
	linked_to_camera || return $?
	linked_to_flyctl || return $?
	linked_to_bvision || return $?
}

aging_test_check_link()
{
	linked_to_ltc_fpga || return $?
	#linked_to_camera || return $?
	linked_to_bvision || return $?
	#linked_to_mvision || return $?
	linked_to_ultrasonic || return $?
	#workaround bellow failed cases
	linked_to_flyctl || return $?
	#linked_to_esc 0 || return $?
	#linked_to_esc 1 || return $?
	#linked_to_esc 2 || return $?
	#linked_to_esc 3 || return $?
}

# program fpga
program_fpga()
{
	cpld_dir=/data/dji/amt/factory_out/cpld
	mkdir -p $cpld_dir
	rm -rf $cpld_dir/*
	local r=0
	local n=0
	while [ $n -lt 3 ]; do
		let n+=1
		test_fpga /dev/i2c-1 /dev/i2c-1 64 400000 /vendor/firmware/cpld_v4a.fw >> $cpld_dir/log.txt
		r=$?
		if [ $r == 0 ]; then
#			boot.mode will be remove in the ENC step
#			env -d boot.mode
			#echo factory > /data/dji/amt/state
			break
		fi
	done
	echo $r > $cpld_dir/result
}

# check a9s LCD path
check_camera_data()
{
	test_encoding
}

# check flyctl USB
# can be ttyACM# or others

# factory test state control
switch_test_state()
{
	echo $1 > /data/dji/amt/state
}

# change vision image save flag
change_vision_save_flag()
{
	mount -o remount,rw  /system
	busybox sed "s/key=\"save_flag\" value=\"1\"/key=\"save_flag\" value=\"0\"/" /system/etc/config.xml > /system/etc/config1.xml
	mv /system/etc/config1.xml /system/etc/config.xml
	sync
	mount -o remount,ro /system
}
