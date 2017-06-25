#!/system/bin/sh
#
# error_action and factory_out_test is useless now
# our current factory_out test flow triggered by the
# PC tools which pass down the test case by dji_sys
#

# include the script lib
. lib_test_cases.sh

RED=145
GREEN=146

red_blink()
{
	local i=0
	while [ i -lt 4 ]; do
		led_on $RED
		led_off $RED
		sleep 0.3
		let i+=1
	done
}

green_blink()
{	local i=0
	while [ i -lt 4 ]; do
		led_on $GREEN
		led_off $GREEN
		sleep 0.3
		let i+=1
	done
}

factory_out_warning()
{
	led_off $RED
	led_off $GREEN
	sleep 1

	while [ 1 ]; do
		red_blink
		sleep 1
		green_blink
		sleep 1
	done
}

# test for 20s
timeout=20

amt=/data/dji/amt
dir=$amt/factory_out
led_blinking=$amt/led_blinking
mkdir -p $dir
# error action
error_action()
{
	echo error_action: \"$2\", error=$1
	if [ -f $dir/result ]; then
		return $1
	fi

	# stop other tests
	touch $dir/result

	# stop blinking, LEDs off
	rm -rf $led_blinking
	sync
	sleep 2		# ensure no conflict with led_blink

	if [ $1 -ne 0 ]; then
		# save test result to file
		echo FAILED, \"$2\", error $1 > $dir/result
		echo factory_out_test failed, error at case: \"$2\"
		led_on $RED
		led_off $GREEN
	else
		echo PASSED > $dir/result
		echo factory_out_test passed ---------------------
		led_on $GREEN
		led_off $RED
	fi
	sync
	exit $1
}

factory_out_test()
{
	# clear previous result
	rm -rf $dir/result

	# both green/red LED off
	led_off $GREEN
	led_off $RED

	# show LED
	touch $led_blinking
	sync
	start_inf_error_stop 1 "led_blink $GREEN"

	# program fpga first
	run_error_action 1 "program_fpga"

	# restart timeout check
	restart

	# memory test
	start_timeout_error_action 4 "test_mem -s 0x200000 -l 1"

	# codec test
	start_timeout_error_action 1 "test_multi_enc 7"

	# communication test
	start_timeout_error_action 1 "factory_out_check_link && sleep 5"

	# camera LCD test
	start_timeout_error_action 1 "check_camera_data"
}

if [ -f $dir/result ]; then
	factory_out_result=`cat $dir/result`
	if [ $factory_out_result == passed ]; then
		exit 0
	fi
fi
#start
test_cpld.sh

if [ $? != 0 ];then
	program_fpga
	echo "program_fpga" > /tmp/wtt
fi

factory_out_warning &

part_check.sh

insmod /system/lib/modules/comip_cam.ko

# enable adb in factory_out mode for debug purpose
adb_en.sh

mkdir -p /data/dji/log
mkdir -p /data/dji/cfg/test

# CP SDR channel
dji_net.sh uav &
ifconfig rndis0 192.168.42.2

/system/bin/dji_hdvt_uav -x -b &


# Start system service
/system/bin/dji_sys &

# Start adb/usbmuxd service
export HOME=/data
#adb start-server
usbmuxd -v -v

#clean vision ready flag
rm -f /tmp/vision_ready

# Start vision service
/system/bin/dji_vision &

# Init Wi-Fi module
/system/bin/test_wifi_init.sh

# set A9 as YUV test mode
dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c F4 -1 1b -q 7
