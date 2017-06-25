#!/bin/sh
#
# Remove USB modules in S2 IPCAM...
#

kernel_ver=$(uname -r)

if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ehci-hcd.ko ]; then
        rmmod ehci-hcd
fi

if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/core/usbcore.ko ]; then
        rmmod usbcore
fi

if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/usb-common.ko ]; then
        rmmod usb-common
fi

