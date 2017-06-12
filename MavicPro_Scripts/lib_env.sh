#
# help to setup some global variables
#
chip_id=`busybox devmem 0xa0820220 32`

if [ ${HOSTNAME:-3} = "gnd" -o ${HOSTNAME:0-5:2} = "rc" ]; then
	dev_type="gnd"
	local_ip="192.168.41.2"
	remote_ip="192.168.41.1"
else
	dev_type="uav"
	local_ip="192.168.41.1"
	remote_ip="192.168.41.2"
fi
if [ ${HOSTNAME} = "wm330_dz_vp0001_v1" -o ${HOSTNAME} = "wm330_dz_vp0001_v2" -o ${HOSTNAME} = "wm330_dz_vp0001_v5" ]; then
	wireless_type="lb"
else
	wireless_type="sdr"
fi

if [ -f /data/dji/cfg/test/thermal_test ]; then
	echo "thermal_test, no sdr support"
else
	if [ $wireless_type = "sdr" ]; then
		modem_info.sh auto
	fi
fi

cd /system/bin/
