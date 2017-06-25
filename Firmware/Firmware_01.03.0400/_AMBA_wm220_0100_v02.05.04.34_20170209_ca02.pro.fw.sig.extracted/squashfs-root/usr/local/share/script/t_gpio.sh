#!/bin/sh

if [ $# -eq 0 ] || [ "${1}" == "--help" ] ; then
	echo "set gpio 93 to 0: $0 93 0"
	echo "read gpio 93 value: $0 93"
	exit 0
fi

proc_gpio_write()
{
	echo "t gpio ${1} sw out${2}"

	gpiohex=`printf %02x ${1}`

	# "C"onfig gpio sw output (0x1)
	echo -en 'c\x'"${gpiohex}"'\x01' > /proc/ambarella/gpio

	if [ "${2}" == "0" ]; then
		# "W"rite output 1(0x0)
		echo -en 'w\x'"${gpiohex}"'\x00' > /proc/ambarella/gpio
	fi

	if [ "${2}" == "1" ]; then
		# "W"rite output 1(0x1)
		echo -en 'w\x'"${gpiohex}"'\x01' > /proc/ambarella/gpio
	fi
}

proc_gpio_read()
{
	cat /proc/ambarella/gpio | cut -c $(($1 + 1))
}

sys_gpio_write()
{
	echo "t gpio ${1} sw out${2}"

	if [ ! -e /sys/class/gpio/gpio${1} ]; then
		echo ${1} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${1}/direction
	fi

	if [ -e /sys/class/gpio/gpio${1} ]; then
		echo ${2} > /sys/class/gpio/gpio${1}/value
	fi
}

sys_gpio_read()
{
	if [ ! -e /sys/class/gpio/gpio${1} ]; then
		echo ${1} > /sys/class/gpio/export
	fi

	if [ -e /sys/class/gpio/gpio${1} ]; then
		cat /sys/class/gpio/gpio${1}/value
	fi
}

if [ $# -eq 2 ]; then
	if [ -e /proc/ambarella/gpio ]; then
		proc_gpio_write ${1} ${2}
	elif [ -e /sys/class/gpio ]; then
		sys_gpio_write ${1} ${2}
	else
		echo "/proc/ambarella/gpio does not exist"
	fi
else
	if [ -e /proc/ambarella/gpio ]; then
		proc_gpio_read ${1}
	elif [ -e /sys/class/gpio ]; then
		sys_gpio_read ${1}
	else
		echo "/proc/ambarella/gpio does not exist"
	fi
fi
