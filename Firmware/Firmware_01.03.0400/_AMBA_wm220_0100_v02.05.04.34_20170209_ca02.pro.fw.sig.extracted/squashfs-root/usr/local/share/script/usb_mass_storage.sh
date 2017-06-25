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

	echo host > /proc/ambarella/usbphy0

	#Install USB module
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/core/usbcore.ko ]; then
		modprobe usbcore
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ehci-hcd.ko ]; then
		modprobe ehci-hcd
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ohci-hcd.ko ]; then
		modprobe ohci-hcd
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/udc-core.ko ]; then
		modprobe udc-core
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/ambarella_udc.ko ]; then
		modprobe ambarella_udc
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/fs/configfs/configfs.ko ]; then
		modprobe configfs
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/libcomposite.ko ]; then
		modprobe libcomposite
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/g_$SYS_USB_G_TYPE.ko ]; then
		modprobe g_$SYS_USB_G_TYPE $SYS_USB_G_PARAMETER
	fi
	# The followings are for USB mass storage.
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/scsi_mod.ko ]; then
		modprobe scsi_mod
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/sd_mod.ko ]; then
		modprobe sd_mod
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/storage/usb-storage.ko ]; then
		modprobe usb-storage
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

