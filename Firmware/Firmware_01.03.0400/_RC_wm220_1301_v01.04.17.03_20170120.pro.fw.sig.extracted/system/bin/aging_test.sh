# include the script lib
. lib_test.sh
. lib_test_cases.sh
. lib_test_220rc.sh

# test for 2 hours (7200s)
timeout=7200
amt=/data/dji/amt
dir=$amt/aging_test
tmp_dir=$amt/aging_test_tmp
led_blinking=$amt/led_blinking
mkdir -p $dir

fail_cnt=$amt/fail_cnt
success_cnt=$amt/success_cnt

fail_postfix=fail_result__
success_postfix=success_result__

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
	echo error_action: \"$2\", error=$1
	echo $BASHPID
	echo

	me=$BASHPID

	if [ $1 -ne 0 ]; then
		echo $2 >> $fail_cnt
		touch $tmp_dir/${me}_${fail_postfix}

		echo FAILED, \"$2\", error $1 >> $dir/result
		echo aging_test failed, error at case: \"$2\"

		# blinking the red led
		touch $led_blinking
		sync
		start_inf_error_stop 1 "led_blink $RED"
	else
		echo $2 >> $success_cnt
		touch $tmp_dir/${me}_${success_postfix}
	fi

	#cnt_nok=`busybox wc -l $fail_cnt | busybox awk '{print $1}'`
	#cnt_ok=`busybox wc -l $success_cnt | busybox awk '{print $1}'`

	cnt_nok=`ls -l $tmp_dir | grep -c "${fail_postfix}"`
	cnt_ok=`ls -l $tmp_dir | grep -c "${success_postfix}"`
	cnt_sum=$(($cnt_nok+$cnt_ok))
	echo cnt_nok=$cnt_nok
	echo cnt_ok=$cnt_ok
	echo cnt_sum=$cnt_sum

	if [ $cnt_sum -ge $sum_num ]; then
		touch $dir/finished
		sync
		# stop blinking
		rm -rf $led_blinking
		sync
		sleep 5
		if [ $cnt_nok -gt 0 ]; then

			led_on $RED
			led_off $GREEN
			test_rc_lcd.sh aging_fail
			echo factory > $amt/state
		else
			echo PASSED > $dir/result
			echo aging test passed ---------------------
			led_on $GREEN
			led_off $RED
			test_rc_lcd.sh aging_pass
			echo factory > $amt/state
		fi
		sync
		exit $cnt_nok
	fi
}

check_with_mb_ctrl()
{
	linked_to_mcu || return $?
	sleep 1
	echo "check mcu version finished."

	aging_test_check_link || return $?
	sleep 1
	echo "check lcd finished."

	test_vibrator.sh
	echo "check vibrator finished."
	sleep 2

	test_buzzer.sh 3
	echo "enable buzzer."
	sleep 2

	test_buzzer.sh 0
	echo "disable buzzer."
	sleep 2
	echo
}

monitor_work()
{
	charging_status=2
	while true; do
		fg_val=`get_rc_capacity`

		if [ $fg_val -gt $fg_hi_th ]; then
			if [ $charging_status -ne 0 ]; then
				charging_status=0
				disable_charging
			fi
			current_range=$HI_RANGE
		elif [ $fg_val -lt $fg_lo_th ]; then
			if [ $charging_status -ne 1 ]; then
				charging_status=1
				enable_charging
			fi
			current_range=$LO_RANGE
		else
			charging_status=2
			current_range=$MID_RANGE
		fi

		echo "fg_val = $fg_val, current_range = $current_range, charging_status = $charging_status"

		#check every 2 minute
		sleep 120
	done
}

aging_test()
{
	# clear previous result
	rm -rf $dir/finished
	rm -rf $dir/result

	# both green/red LED off
	led_off $GREEN
	led_off $RED

	# show LED
	touch $led_blinking
	sync
	start_inf_error_stop 1 "led_blink $GREEN"

	start_timeout_error_action  $link_test_thread_num "check_with_mb_ctrl"

	# memory test
	start_timeout_error_action $mem_test_thread_num "test_mem -s 0x200000 -l 10"

	# codec test
	start_timeout_error_action $codec_test_thread_num "test_multi_enc 7"
}

sleep 20
config_timeout > $amt/aging_test/log.txt

rm -rf $amt/aging_test/monitor.txt
monitor_work >> $amt/aging_test/monitor.txt &

rm -rf $fail_cnt
rm -rf $success_cnt
rm -rf $tmp_dir

mkdir $tmp_dir

touch $fail_cnt
touch $success_cnt

link_test_thread_num=1
mem_test_thread_num=4
codec_test_thread_num=1
sum_num=$(($link_test_thread_num+$mem_test_thread_num+$codec_test_thread_num))

aging_test >> $amt/aging_test/log.txt
