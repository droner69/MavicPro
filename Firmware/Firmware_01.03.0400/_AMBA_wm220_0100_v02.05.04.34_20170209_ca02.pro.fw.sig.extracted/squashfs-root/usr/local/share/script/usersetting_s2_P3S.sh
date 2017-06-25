#!/bin/sh

#date -s 201404040000

#usb0
#echo device > /proc/ambarella/usbphy0
modprobe usbcore
modprobe udc-core
#modprobe ambarella_udc
modprobe libcomposite
#modprobe g_serial
#modprobe g_ether
#ifconfig usb0 192.168.1.3 up
#usb1
#insmod  /lib/modules/3.10.71/kernel/updates/drivers/68013.ko
modprobe ehci_hcd

insmod  /lib/modules/3.10.71/kernel/updates/drivers/68013.ko
insmod  /lib/modules/3.10.71/kernel/updates/drivers/rpmsg_trans.ko
wait $!

tcpsvd 0 21 ftpd -w /tmp/FL0 &

if [ -e /usr/bin/cam_server ]; then
    cam_server 0 2 &
fi

if [ -e /usr/local/share/script/Guard.sh ]; then
    /usr/local/share/script/Guard.sh &
fi

if [ -e /usr/bin/rpc_ctrl_cln ]; then
    rpc_ctrl_cln
fi

echo "User Setting Step 2 Finish"

