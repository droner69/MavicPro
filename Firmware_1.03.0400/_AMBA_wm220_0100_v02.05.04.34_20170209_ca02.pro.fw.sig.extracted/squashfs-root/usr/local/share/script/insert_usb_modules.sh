#!/bin/sh
#
# Init S2 IPCAM...
#

if [ -f /etc/ambarella.conf ]; then
	. /etc/ambarella.conf
fi

start()
{
	kernel_ver=$(uname -r)
	SYS_USB_G_TYPE="serial"
	SYS_USB_G_PARAMETER="use_acm=1"

	echo host > /proc/ambarella/uport

	#Install USB module
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/usb-common.ko ]; then
		modprobe usb-common
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/core/usbcore.ko ]; then
		modprobe usbcore
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ehci-hcd.ko ]; then
		modprobe ehci-hcd
	fi
}

stop()
{
	kernel_ver=$(uname -r)
}

restart()
{
	stop
	start
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart|reload)
		restart
		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit $?

