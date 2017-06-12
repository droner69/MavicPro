# Check the update recovery log index
index=1
if [ -f /cache/update_recovery_index ]; then
	local tmp=`cat /cache/update_recovery_index`
	if [ 9 -le $tmp ]; then
		echo 1 > /cache/update_recovery_index
	else
		let tmp+=1
		echo $tmp > /cache/update_recovery_index
		index=$tmp
	fi
else
	echo 1 > /cache/update_recovery_index
fi
update_log=/cache/update_recovery_log$index

if [ -f /system/etc/recovery.img ]; then
	echo "Start recovery.img update flow." > $update_log
else
	echo "No need to update recovery.img, since /system/etc/recovery.img not exist." > $update_log
	busybox sync
	exit 0
fi

if [ -f /cache/update_recovery_start ]; then
	echo "Already set start flag last time." >> $update_log
else
	#set a flag in /cache/update_recovery_start
	echo "Set start flag." >> $update_log
	touch /cache/update_recovery_start
fi

# Get the 4k size header of recovery.img & recovery partition.
busybox dd if=/system/etc/recovery.img of=/tmp/rec_4k_1 bs=1024 count=4
busybox dd if=/dev/block/platform/comip-mmc.1/by-name/recovery of=/tmp/rec_4k_2 bs=1024 count=4
echo "Create rec_4k_* ready." >> $update_log

# Start update recovery.img flow.
if [ -f /tmp/rec_4k_1 -a -f /tmp/rec_4k_2 ]; then
	busybox diff /tmp/rec_4k_1 /tmp/rec_4k_2
	if [ 0 -ne $? ]; then
		dji_verify -n recovery /system/etc/recovery.img
		if [ 0 -eq $? ]; then
			echo "Recovery.img verify done." >> $update_log
			#Actually start to write recovery.img.
			echo "Start to write recovery.img." >> $update_log
			cp /system/etc/recovery.img /tmp/recovery.img
			busybox truncate -c -s 12M /tmp/recovery.img
			busybox dd if=/tmp/recovery.img of=/dev/block/platform/comip-mmc.1/by-name/recovery skip=4 seek=4 bs=1024 count=12284
			busybox dd if=/tmp/recovery.img of=/dev/block/platform/comip-mmc.1/by-name/recovery bs=1024 count=4
			echo "Write recovery.img done." >> $update_log
		else
			echo "Recovery.img verify failure." >> $update_log
		fi
	else
		echo "The 2 rec_4k_* is the same, no need to update recovery.img." >> $update_log
	fi
fi
rm /cache/update_recovery_start
busybox sync

