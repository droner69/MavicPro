#!/bin/sh

LOGGER ()
{
	if [ "${sysl}" != "" ]; then
		logger "${b0}:${@}"
	else
		echo "$@"
	fi
}

sysl=`ps | grep syslogd | grep -v grep`
b0=`basename ${0}`

if [ -e /dev/hidraw0 ]; then
	LOGGER "/dev/hidraw0 found"
	exit 0
fi

#0005:046D:B30C.001F
n=0
while [ "`ls /sys/bus/hid/devices/`" == "" ] && [ $n -ne 10 ]; do
	n=$(($n + 1))
	sleep 0.1
done
if [ "`ls /sys/bus/hid/devices/`" == "" ]; then
	LOGGER "/sys/bus/hid/devices/* not found"
	exit 1
fi

#start probe
new_id=`ls /sys/bus/hid/devices/ | sed 's|[:.]| |g' | tail -n 1`
LOGGER "echo ${new_id} > /sys/bus/hid/drivers/apple/new_id"
echo ${new_id} > /sys/bus/hid/drivers/apple/new_id

#hidraw0
n=0
while [ "`ls /sys/class/hidraw/`" == "" ] && [ $n -ne 10 ]; do
	n=$(($n + 1))
	sleep 0.1
done
if [ "`ls /sys/class/hidraw/`" == "" ]; then
	LOGGER "/sys/class/hidraw/* not found"
	exit 1
fi
