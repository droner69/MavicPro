#!/bin/sh
#This script is used to mount/umount sd card in ambafs.
#$1: mount or umount
#$2: target directory
#$3: source device
#$4: file system type

if [ "$1" = "mount" ]; then
	STR=$3" on "$2" type "$4
	RET=`mount | grep "$STR"`
	if [ -z "$RET" ]; then
		echo $STR
		RET=`mount -t $4 $3 $2`
	fi
fi

if [ "$1" = "umount" ]; then
	RET=`umount $2`
fi
