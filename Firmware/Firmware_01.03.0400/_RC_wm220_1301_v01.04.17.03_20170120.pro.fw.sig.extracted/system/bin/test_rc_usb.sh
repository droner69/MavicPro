if [ -f /data/dji/amt/factory_out/scsi_device ];then
	rm /data/dji/amt/factory_out/scsi_device
	sync
	exit 0
else
	exit 1
fi
