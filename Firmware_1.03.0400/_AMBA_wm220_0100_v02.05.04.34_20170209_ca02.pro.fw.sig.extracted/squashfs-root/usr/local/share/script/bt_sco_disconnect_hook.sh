#!/bin/sh
HCI_DRIVER=`cat /pref/bt.conf | grep -Ev "^#" | grep HCI_DRIVER | cut -c 12-`
if [ "${HCI_DRIVER}" == "ath3k" ]; then
	echo killall abtfilt
	killall abtfilt 2>/dev/null
fi
