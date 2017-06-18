dump_dir=/data/dji/log/

add_timestamp()
{
	echo >> $dump_file
	date >> $dump_file
}

check_lmi42_status()
{
	add_timestamp
	modem_info.sh cps >> $dump_file
	busybox ifconfig | grep lmi42 >>  $dump_file
	modem_info.sh lmi42 | grep "send" >> $dump_file
	modem_info.sh lmi42 | grep "notbusy" >> $dump_file
}

mkdir -p $dump_dir
dump_file=$dump_dir/upgrade_lmi42.log
echo $dump_file
touch $dump_file
if [ $DEVICE_TYPE = "UAV" ]; then
	busybox ping -w 8 192.168.41.2 > /dev/null &
else
	busybox ping -w 8 192.168.41.1 > /dev/null &
fi
check_lmi42_status
sleep 2
check_lmi42_status
sleep 2
check_lmi42_status
sync
