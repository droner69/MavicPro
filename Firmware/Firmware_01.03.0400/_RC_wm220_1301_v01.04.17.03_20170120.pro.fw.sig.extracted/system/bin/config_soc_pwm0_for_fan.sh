#!/system/bin/sh

PERIOD=1000000000
# $1 is duty-cycle
config_pwm0()
{
	#request
	echo 0 > /sys/class/pwm/pwmchip0/export
	#disable
	echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable

	#configure
	echo $PERIOD > /sys/class/pwm/pwmchip0/pwm0/period
	echo $1 > /sys/class/pwm/pwmchip0/pwm0/duty

	#enable
	echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
	#release
	echo 0 > /sys/class/pwm/pwmchip0/unexport
}

get_1860_temp()
{
    TEMPERATURE_1860=`cat /proc/driver/comip-thermal | grep 'last is' | busybox awk '{ print $15; }'`
    return $TEMPERATURE_1860
}

RUNNING=1
STOPPED=0
FULL_SPEED=1000000000
ZERO_SPEED=0

# the policy is internal, the parameter is checking period
ctrl_loop()
{
	while true; do
		get_1860_temp
		cur_temp=$?
		# echo "cur_temp = $cur_temp"
		if [ $cur_temp -gt 60 ] && [ $cur_fan_status -eq $STOPPED ]; then
			config_pwm0 $FULL_SPEED
			cur_fan_status=$RUNNING
		elif [ $cur_temp -lt 55 ] && [ $cur_fan_status -eq $RUNNING ]; then
			config_pwm0 $ZERO_SPEED
			cur_fan_status=$STOPPED
		fi

		sleep $1
	done
}

cur_fan_status=$STOPPED
ctrl_loop 10
