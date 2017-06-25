#!/system/bin/sh
hackid_fix="544d060608000000"
channel_fix="544d070602000000"
hackid_gnd="CDAB0E"
hackid_uav="CDAB1E"
band="01"
cfgfile="/data/dji/cfg/amt_sdr_test.cfg"
okfile="/data/dji/cfg/sdr_link_ok"
action=""
busybox rm -rf /data/dji/cfg/sdr_link_ok
#disable netroork to avoid wifi/sdr switch
#reboot modem to make sure it worked normally
function pre_init()
{
	echo "pre_init"
	if [ $DEVICE_TYPE = "UAV" ]; then
		setprop dji.network_service 0
		setprop dji.encoding_service 0
		setprop dji.camera_service 0
		/system/bin/antenna_switch.sh SDR
		sleep 2
	fi
}

# create confgure file
if [ "$1" = "f" ]; then
	ch=$2
	action="fix"
elif [ "$1" = "d" ]; then
	rm -f "$cfgfile"
	echo "log: remove cfg file"
	exit 0
elif [ "$1" = "p" ]; then
	ch=$2
	action="ping"
else
#auto configure channel and band after reboot, wait 2 second for sdrs and hdvt ready
	if [ -f "$cfgfile" ]; then
		ch=`busybox cat "$cfgfile" | grep "channel" | busybox awk -F":" '{print $2}'`
		action="fix"
		echo "get ch $ch"
	else
		echo "can not find $cfgfile"
		exit 1
	fi
	sleep 2
fi

if [ "$ch" -lt "29" ]; then
	if [ "$1" = "f" ]; then
		echo "channel:$ch" > "$cfgfile"
		echo "log:channel:$ch"
	fi
else
	echo "$ch is invalid"
	exit 1
fi


if [ $DEVICE_TYPE = "GND" ] || [ $DEVICE_TYPE = "GLASS" ]; then
	channel=`busybox printf "%02X" $ch`
	hack_id="$hackid_fix$channel$hackid_gnd$channel$hackid_uav"
	band_ch="$channel_fix$channel$band"
elif [ $DEVICE_TYPE = "UAV" ]; then
	channel=`busybox printf "%02X" $ch`
	hack_id="$hackid_fix$channel$hackid_uav$channel$hackid_gnd"
	band_ch="$channel_fix$channel$band"
else
	echo "$DEVICE_TYPE is unknown"
	exit 1
fi

pre_init

echo "hackid:$hack_id"
echo "band:$band_ch"
#fix freq and channel
if [ "$action" = "fix" ]; then
	i=0
	while [ $i -lt 3 ]; do
		if [ $DEVICE_TYPE = "GND" ] || [ $DEVICE_TYPE = "GLASS" ]; then
			echo "$HOSTNAME is GND"
			result_1=`dji_mb_ctrl -S test -R local -g 14 -t 0 -s 9 -c 0x2c -a 00 $hack_id | grep "Send message"`
			result_2=`dji_mb_ctrl -S test -R local -g 14 -t 0 -s 9 -c 0x2c -a 00 $band_ch | grep "Send message"`
		elif [ $DEVICE_TYPE = "UAV" ]; then
			echo "$HOSTNAME is UAV"
			result_1=`dji_mb_ctrl -S test -R diag -g 9 -t 0 -s 9 -c 0x2c -a 00 $hack_id | grep "Send message"`
			result_2=`dji_mb_ctrl -S test -R diag -g 9 -t 0 -s 9 -c 0x2c -a 00 $band_ch | grep "Send message"`
		fi
		if [ -n "$result_1" ] && [ -n "$result_2" ]; then
			echo "configure cp is ok"
		else
			echo "$i mb_ctrl send failed"
		fi
		i=`busybox expr $i + 1`
		sleep 2
	done
        #msg for sync with hdvt service
	/system/bin/sdrs_log_cmd hdvt 32
fi

if [ "$action" = "ping" ]; then
	i=0
	while [ $i -lt 10 ]; do
		if [ $i -eq 2 ] || [ $i -eq 6 ]; then
			if [ $DEVICE_TYPE = "GND" ] || [ $DEVICE_TYPE = "GLASS" ]; then
				echo "$HOSTNAME is $DEVICE_TYPE"
				result_1=`dji_mb_ctrl -S test -R local -g 14 -t 0 -s 9 -c 0x2c -a 00 $hack_id | grep "Send message"`
				result_2=`dji_mb_ctrl -S test -R local -g 14 -t 0 -s 9 -c 0x2c -a 00 $band_ch | grep "Send message"`
			elif [ $DEVICE_TYPE = "UAV" ]; then
				echo "$HOSTNAME is UAV"
				result_1=`dji_mb_ctrl -S test -R diag -g 9 -t 0 -s 9 -c 0x2c -a 00 $hack_id | grep "Send message"`
				result_2=`dji_mb_ctrl -S test -R diag -g 9 -t 0 -s 9 -c 0x2c -a 00 $band_ch | grep "Send message"`
			fi
		fi
		# Wait modem ready for use
		sleep 1
		if [ $DEVICE_TYPE = "GND" ] || [ $DEVICE_TYPE = "GLASS" ]; then
			dji_mb_ctrl -S test -R local -g 14 -t 0 -s 9 -c 0x2f
		elif [ $DEVICE_TYPE = "UAV" ]; then
			dji_mb_ctrl -S test -R diag -g 9 -t 0 -s 9 -c 0x2f
		fi
		sleep 1
		if [ -f "$okfile" ]; then
			echo "loop $i: ping peer ok"
			exit 0
		else
			echo "loop $i: ping peer failed"
		fi
		i=`busybox expr $i + 1`
	done
	exit 1
else
	exit 0
fi
