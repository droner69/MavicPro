if [ -f /cache/update_recovery_start ]; then
	echo "Recovery.img is updating now."
	exit 0
fi

if [ -f /cache/ota.zip ]; then
	busybox unzip /cache/ota.zip normal.img -d /tmp
	if [ -f /tmp/normal.img ]; then
		dji_verify -n normal /tmp/normal.img
		if [ $? != 0 ]; then
			echo " "
			echo "*******************************************************************************************"
			echo "dji_verify normal.img failure, please make sure that you've used a right user/prod ota.zip."
			echo "*******************************************************************************************"
			echo " "
			exit 1
		fi
	else
		echo "**************************************"
		echo "unzip normal.img from ota.zip failure."
		echo "**************************************"
		exit 1
	fi
	mkdir -p /cache/recovery
	echo "--update_package=/cache/ota.zip" > /cache/recovery/command
	sync
	env boot.mode recovery
	reboot recovery
else
	echo "********************************************"
	echo "Please push ota.zip to /cache/ota.zip first."
	echo "********************************************"
fi
