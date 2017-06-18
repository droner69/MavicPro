if [ -f /data/dji/amt/factory_out/scsi_device ];then
	exit 0
fi

while [ 1 ]; do
	cd /sys/class/scsi_device
    ret=`dmesg | grep "my_if0_en ok" | busybox wc -l`
	if [ $ret != 0 ];then
		mkdir -p /data/dji/amt/factory_out/
		touch /data/dji/amt/factory_out/scsi_device
		sync
		exit 0
	fi
	sleep 2
done
