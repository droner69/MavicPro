#!/system/bin/sh

test_file_name="temptestfile"
test_log_file="/cache/part_check.log"

part_ud_fstype="ext4"
part_ud_fsflag="rw,async,noatime,data=ordered"
part_bb_fstype="ext4"
part_bb_fsflag="rw,async,noatime,data=ordered"
part_cc_fstype="ext4"
part_cc_fsflag="rw,async,noatime,data=ordered"


test_file_create()
{
	#dd if=/dev/zero of=/tmp/$test_file_name bs=1024 count=10240 1>/dev/null 2>/dev/null
	echo "1234567890qwertyuiop" > /tmp/$test_file_name
}

test_file_remove()
{
	rm /tmp/$test_file_name
}

do_fsck()
{
	if [ $2 = "ext4" ]; then
		e2fsck -p /dev/block/platform/comip-mmc.1/by-name/$1
		e2fsck -y /dev/block/platform/comip-mmc.1/by-name/$1
	else
		busybox mount -f -t $2 /dev/block/platform/comip-mmc.1/by-name/$1 /tmp
	fi
	return $?
}

do_format()
{
	if [ $2 = "ext4" ]; then
		busybox mke2fs -F /dev/block/platform/comip-mmc.1/by-name/$1
	else
		busybox mkdosfs /dev/block/platform/comip-mmc.1/by-name/$1
	fi
}

partition_fs_check()
{
	umount $2
	umount /ftp/$2
	do_fsck $1 $3
	if [ $? != 0 ]; then
		echo "Partition $1 (mount to $2) fs check fail, formit it..." >> $test_log_file
		do_format $1 $3
	else
		echo "Partition $1 (mount to $2) fs check normal."
	fi
	busybox mount -t $3 -o $4 /dev/block/platform/comip-mmc.1/by-name/$1 /$2
}

partition_mount_check()
{
	mount | grep "/by-name/$1 /$2 $3" | grep rw
	if [ $? != 0 ]; then
		echo "Partition $1 (mount to $2) mount check fail, format it..." >> $test_log_file
		umount /$2
		do_format $1 $3
		reboot
	else
		echo "Partition $1 (mount to $2) mount check normal."
	fi
}

partition_write_check()
{
	cp /tmp/$test_file_name /$2
	busybox diff /tmp/$test_file_name /$2/$test_file_name
	if [ $? != 0 ];then
		echo "Partition $1 (mount to $2) write check fail, format it..." >> $test_log_file
		rm -rf /$2/$test_file_name

		umount /$2
		do_format $1 $3
		echo "Format $1 (mount to $2) done, reboot..." >> $test_log_file
		reboot
	else
		echo "Partition $1 (mount to $2) write check normal."
		rm -rf /$2/$test_file_name
	fi
}

# Check partitions fs and mount it
partition_fs_check userdata data     $part_ud_fstype $part_ud_fsflag
partition_fs_check blackbox blackbox $part_bb_fstype $part_bb_fsflag
partition_fs_check cache cache       $part_cc_fstype $part_cc_fsflag

# Check partitions mounted and is writeable
partition_mount_check userdata data     $part_ud_fstype
partition_mount_check blackbox blackbox $part_bb_fstype
partition_mount_check cache cache       $part_cc_fstype

# Check partitions writeable
test_file_create
partition_write_check userdata data     $part_ud_fstype
partition_write_check blackbox blackbox $part_bb_fstype
partition_write_check cache cache       $part_cc_fstype
test_file_remove

# Duplicate mount
mount -t $part_ud_fstype -o $part_ud_fsflag /dev/block/platform/comip-mmc.1/by-name/userdata /ftp/upgrade
mount -t $part_bb_fstype -o $part_bb_fsflag /dev/block/platform/comip-mmc.1/by-name/blackbox /ftp/blackbox

