#!/bin/sh

#date -s 201404040000

/usr/local/share/script/usb_func_sw_P1H.sh ins

insmod  /lib/modules/3.10.71/kernel/updates/drivers/rpmsg_trans.ko
wait $!

tcpsvd 0 21 ftpd -w /tmp/FL0 &

if [ -e /usr/bin/cam_server ]; then
    cam_server 0 2 &
fi

if [ -e /usr/bin/hdr_merge ]; then
    hdr_merge &
fi

if [ -e /usr/local/share/script/Guard.sh ]; then
    /usr/local/share/script/Guard.sh &
fi

if [ -e /usr/bin/rpc_ctrl_cln ]; then
    rpc_ctrl_cln
fi

echo "User Setting Step 2 Finish"

