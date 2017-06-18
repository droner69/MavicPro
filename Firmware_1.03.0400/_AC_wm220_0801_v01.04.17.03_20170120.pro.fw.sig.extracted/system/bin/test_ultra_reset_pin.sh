#!/system/bin/sh

# the idea is disable the reset pin, and check the device version,
# if it can be got successfully, fail the test
# suppose the json table is valid

if [ $# == 1 ];then
	GPIO_FOR_CM0=$1
else
	GPIO_FOR_CM0=80
fi
echo "ultra reset pin $GPIO_FOR_CM0"

GPIO_FOR_MA2100=108
result1=0

prepare() {
	echo $1 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio$1/direction
}

do_test() {
	echo 0 > /sys/class/gpio/gpio$1/value
}

check_result() {
	case $1 in
		cm0)
			# check reset pin for CM0(ultrasonic)
			dji_mb_ctrl -S test -R diag -g 8 -t 4 -s 0 -c 1
			return $?
			;;
		*)
			echo "invalid argument"
			return 0
			;;
	esac
}

clean_up() {
	echo 1 > /sys/class/gpio/gpio$1/value
	echo $1 > /sys/class/gpio/unexport
}

# check CM0:
prepare $GPIO_FOR_CM0
do_test $GPIO_FOR_CM0
check_result cm0
if [ $? -eq 0 ]; then
	echo "CM0 reset pin checking fails.."
	result1=1
fi
clean_up $GPIO_FOR_CM0

if [ $result1 -ne 0 ]; then
	echo "reset pin checking fails..."
	exit 1
else
	echo "reset pin checking successes..."
	exit 0
fi
