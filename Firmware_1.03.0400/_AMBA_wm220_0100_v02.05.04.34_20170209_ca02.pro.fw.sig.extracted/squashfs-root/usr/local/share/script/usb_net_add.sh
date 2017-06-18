#!/bin/sh

echo "Add usb net $1"

ifconfig $1 192.168.1.3

if [ t"$1" == t"usb0" ]; then
    arping -I $1 -A -c 10 -s 192.168.1.3 192.168.1.10 &
fi

