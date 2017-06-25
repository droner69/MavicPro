#!/system/bin/sh
#
# error_action and factory_out_test is useless now
# our current factory_out test flow triggered by the
# PC tools which pass down the test case by dji_sys
#

# include the script lib
. lib_test_cases.sh

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
part_check.sh

setprop dji.sdrs 1

# enable adb in factory_out mode for debug purpose
adb_en.sh

mkdir -p /data/dji/log
mkdir -p /data/dji/cfg/test

setprop dji.sdrs_log 1
# rndis
#ifconfig ra0 192.168.1.2

# CP SDR channel
dji_net.sh gnd &
#usbmuxd -v -v
# Start services
setprop dji.monitor_service 1
setprop dji.hdvt_service 1
setprop dji.system_service 1

setprop dji.factory_out 1

adb start-server

#config for sound
tinymix 0 0
tinymix 1 1
tinymix 2 0
tinymix 5 31
tinymix 6 31 31
tinymix 7 31
tinymix 10 103
tinymix 11 103 103
tinymix 12 103
tinymix 24 1
tinymix 37 1
tinymix 38 1
tinymix 40 1
tinymix 41 1
tinymix 45 1
tinymix 46 1
tinymix 50 0
tinymix 51 0

test_fan.sh 1
check_scsi.sh&
getevent > /tmp/rc_key_event.log&

#show factory_out warning
local i=0
while [ $i -lt 5 ];do
	let i+=1
	dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 0000000000000000000000000000000000000000000000000000000000464143544F52592D4F55540000
	sleep 10
done
