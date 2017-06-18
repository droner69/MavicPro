. lib_test_utils.sh

#
# LED
#

RED=156
GREEN=165

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

led_blink()
{
	if [ ! -f $led_blinking ]; then
		return 1
	fi
	led_on $1 led_blink
	sleep 1
	led_off $1 led_blink
	sleep 1
}

#
# link path test cases
#

linked_to_camera()
{
	cmd_check_ver camera 1 1
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

linked_to_mvision()
{
	cmd_check_ver mvision 17 7
}

linked_to_bvision()
{
	cmd_check_ver ma2100 8 2
#	cmd_check_ver 18 7
}

linked_to_ltc_fpga()
{
	cmd_check_ver ltc_fpgs 8 3
}

linked_to_ultrasonic()
{
	cmd_check_ver ultrasonic 8 4
}

linked_to_mcu()
{
	cmd_check_ver mcu_uart 6 0
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
	# linked_to_mcu || return $?
	test_rc_lcd.sh aging_test || return 0
	sleep 1
	test_rc_lcd.sh full || return 0
	test_rc_lcd.sh close || return 0
}

# program fpga
program_fpga()
{
	cpld_dir=/data/dji/amt/factory_out/cpld
	mkdir -p $cpld_dir
	rm -rf $cpld_dir/log.txt
	local r=0
	local n=0
	while [ $n -lt 3 ]; do
		let n+=1
		test_fpga /dev/i2c-1 /dev/i2c-1 64 400000 /vendor/firmware/cpld_v4a.fw >> $cpld_dir/log.txt
		r=$?
		if [ $r == 0 ]; then
#			boot.mode will be remove in the ENC step
#			env -d boot.mode
			echo factory > /data/dji/amt/state
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
