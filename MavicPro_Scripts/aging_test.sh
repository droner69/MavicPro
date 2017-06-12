# include the script lib
. lib_test.sh
. lib_test_cases.sh

# test for 2 hours (7200s)
timeout=7200
amt=/data/dji/amt
dir=$amt/aging_test
led_blinking=$amt/led_blinking
mkdir -p $dir
# aging_test_timeout configure
config_timeout()
{
	if [ -s $amt/aging_test_timeout ]; then
		time=($(cat  $amt/aging_test_timeout))
		if [ $time == 0 ];then
			echo "timeout value should not as 0"
		else
			timeout=$time
		fi
	fi
	echo "aging_test timeout: $timeout"
}
# error action
error_action()
{
	# A9 fail check
	check_a9_aging_state
	if [ $? == 1 ] && [ ! -f /data/dji/amt/a9_aging_test_result ];then
		led_off $GREEN
		echo wtt >> /data/a9_aging_log.txt
		touch $led_blinking
		sync
		start_inf_error_stop 1 "led_blink $RED"
		exit
	fi

	# A9 fail check
	echo error_action: \"$2\", error=$1
	if [ -f $dir/finished ]; then
		return $1
	else
		# mark as finished
		if [ $1 -eq 0 ]; then
			touch $dir/finished
			sync
		fi
	fi

	# stop blinking, LEDs off
	rm -rf $led_blinking
	sync
	sleep 2		# ensure no conflict with led_blink

	if [ $1 -ne 0 ]; then
		# save test result to file
		echo FAILED, \"$2\", error $1 >> $dir/result
		echo aging_test failed, error at case: \"$2\"

		rm -rf $led_blinking
		sync
		sleep 1
		touch $led_blinking
		sync
		if [ $1 -eq 3 ]; then
			start_inf_error_stop 1 "led_quick_blink $GREEN"
		else
			start_inf_error_stop 1 "led_blink $RED"
		fi
		echo factory > $amt/state
		sync
	else
		# already get error
		if [ -f $dir/result ]; then
			led_on $RED
			led_off $GREEN
			touch $led_blinking
		    sync
		    start_inf_error_stop 1 "led_blink $RED"
			echo result >> /data/a9_aging_log.txt
		else
			# 1860 pass, wait until A9 pass
			while true
			do
				check_a9_aging_state
				if [ $? == 0 ];then
					echo "A9 pass" >> /data/a9_aging_log.txt
					break
				fi
				check_a9_aging_state
				if [ $? == 1 ];then
					echo "A9 fail" >> /data/a9_aging_log.txt
					while true
					do
						led_on $RED a9_fail
						sleep 0.1
						led_off $RED a9_fail
						sleep 0.1
						led_on $RED a9_fail
						sleep 0.1
						led_off $RED a9_fail
						sleep 2
					done
				fi
				check_a9_aging_state
				if [ $? == 4 ];then
					echo "A9 hang" >> /data/a9_aging_log.txt
					while true
					do
						led_on $RED a9_hang
						sleep 0.1
						led_off $RED a9_hang
						sleep 0.1
						led_on $RED a9_hang
						sleep 0.1
						led_off $RED a9_hang
						sleep 0.1
						led_on $RED a9_hang
						sleep 0.1
						led_off $RED a9_hang
						sleep 0.1
					done
				fi
				led_on $GREEN waiting_a9
				sleep 0.1
				led_off $GREEN waiting_a9
				sleep 0.1
				led_on $GREEN waiting_a9
				sleep 0.1
				led_off $GREEN waiting_a9
				sleep 1
			done
			echo PASSED > $dir/result
			echo aging test passed ---------------------
			rm -rf $led_blinking
			led_on $GREEN
			led_off $RED
			echo normal > $amt/state
			change_vision_save_flag
			sync
		fi
		sync
		exit $1
	fi
}

serialize_dji_mb_ctrl()
{
	# test acc
	test_fc_status.sh 8 aging_test || return $?
	sleep 1
	# test gypo
	test_fc_status.sh 9 aging_test || return $?
	sleep 1
	# test baro
	test_fc_status.sh 10 aging_test || return $?
	sleep 1
	# test compass
	test_fc_status.sh 11 aging_test || return $?
	sleep 1
	# test gps
#	test_fc_status.sh 12 aging_test || return $?
#	sleep 1
	# test tf card
	test_fc_status.sh 13 aging_test || return $?
	sleep 1
	# test ofdm
	test_fc_status.sh 16 aging_test || return $?
	sleep 1
	# test vision
	test_fc_status.sh 18 aging_test || return $?

	echo "check fc status finished."
	sleep 2
	aging_test_check_link || return $?

	echo "check link finished."
}

aging_test()
{
	# clear previous result
	rm -rf $dir/finished
	rm -rf $dir/result
	rm -rf $dir/temperature

	if [ -e $dir/warning ];then
		rm -rf $dir/warning
	fi

	# both green/red LED off
	led_off $GREEN
	led_off $RED

	# show LED
	touch $led_blinking
	sync
	start_inf_error_stop 1 "led_blink $GREEN"

	# check ultrasonic rest pin
	#setprop dji.vision_service 0
	#start_error_action 1 "check_ultrasonic_reset_pin"
	#setprop dji.vision_service 1
	#sleep 20

	# memory test
	start_timeout_error_action 4 "test_mem -s 0x200000 -l 1000"

	# codec test
	# When enable this test 1860 will not receive pkt from 2100
	# via usb promptly, cause 2100 test failure.
	#start_timeout_error_action 1 "test_multi_enc 7"

	# vision test
	start_timeout_error_action 1 "dji_vision_log_check.sh $timeout"

	# communication test
	start_timeout_error_action 1 "serialize_dji_mb_ctrl && sleep 5"

	#temperatue monitor
	start_timeout_error_action 1 "aging_temp_monitor.sh && sleep 5"

	# ping a9 usb path
	#start_timeout_error_action 1 "test_a9_usb.sh"
}

sleep 20
config_timeout > $amt/aging_test/log.txt
aging_test >> $amt/aging_test/log.txt
