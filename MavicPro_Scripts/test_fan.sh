#!/system/bin/sh

# $1 is duty-cycle
config_pwm0()
{
	#request
	echo 0 > /sys/class/pwm/pwmchip0/export
	#disable
	echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable

	#configure
	echo 100 > /sys/class/pwm/pwmchip0/pwm0/period
	echo $1 > /sys/class/pwm/pwmchip0/pwm0/duty

	#enable
	echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
	#release
	echo 0 > /sys/class/pwm/pwmchip0/unexport
}

if [ $1 == 1 ];then
	config_pwm0 100
else
	config_pwm0 0
fi
