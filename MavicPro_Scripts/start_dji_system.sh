#!/system/bin/sh

# Check partitions, try format it and reboot when failed
/system/bin/part_check.sh
#set emmc irq cpu affinity, dw_mci
echo 02 > /proc/irq/66/smp_affinity
echo 02 > /proc/irq/67/smp_affinity

#set ap_dma irq cpu affinity, ap_dma
echo 08 > /proc/irq/34/smp_affinity

/system/bin/wl_link_judge.sh
wl_link_type=$?
if [ $wl_link_type -ge 1 ]; then
	setprop wl.link.prefer SDR
else
	setprop wl.link.prefer WIFI
fi

#check cp_assert log size, if more then 32KB remove it
#do it before sdrs start, so new log would not be lost
if [ -f /data/dji/log/cp_assert.log ]; then
	cp_assert_file_size=`busybox wc -c /data/dji/log/cp_assert.log | busybox awk '{printf $1}'`
	if [ $cp_assert_file_size -gt 32768 ]; then
		rm -rf /data/dji/log/cp_assert.log
	fi
fi
setprop dji.sdrs 1

debug=false
grep production /proc/cmdline >> /dev/null
if [ $? != 0 ];then
	debug=true	# engineering version, enable adb by default
fi

if $debug; then
	/system/bin/adb_en.sh
else
	setprop sys.usb.config rndis,mass_storage,bulk,acm
fi

setprop dji.sdrs_log 1
# set ip address one more time to avoid possible lost
ifconfig usb0 192.168.1.10

# rndis
ifconfig rndis0 192.168.42.2

mkdir /var/lib
mkdir /var/lib/misc
echo > /var/lib/misc/udhcpd.lease
busybox udhcpd
# ftp server on all the interface
busybox tcpsvd -vE 0 21 busybox ftpd -w /ftp &

# dump system/upgrade log to a special file
#logcat | grep DUSS\&5a >> /data/dji/log/upgrade.log &
mkdir -p /data/upgrade/backup
mkdir -p /data/upgrade/signimgs
mkdir -p /cache/upgrade/unsignimgs
mkdir -p /data/upgrade/incomptb

# clean up dump files
rm -Rf /data/dji/dump/5
busybox mv /data/dji/dump/4 /data/dji/dump/5
busybox mv /data/dji/dump/3 /data/dji/dump/4
busybox mv /data/dji/dump/2 /data/dji/dump/3
busybox mv /data/dji/dump/1 /data/dji/dump/2
busybox mv /data/dji/dump/0 /data/dji/dump/1
mkdir /data/dji/dump/0
busybox find /data/dji/dump/ -maxdepth 1 -type f | busybox xargs -I '{}' mv {} /data/dji/dump/0/

# CP SDR channel
dji_net.sh uav &

# Start services
export HOME=/data
setprop dji.monitor_service 1
setprop dji.hdvt_service 1
setprop dji.encoding_service 1
setprop dji.system_service 1

###Here we change it to 15s to avoid ssd probe fail issue##
if [ -f /data/dji/cfg/ssd_en ]; then # Disabled by default
	i=0
	while [ $i -lt 25 ]; do
		if [ -b /dev/block/sda1 ]
		then
			mkdir -p /data/image
			mount -t ext4 /dev/block/sda1 /data/image
			break
		fi
		i=`busybox expr $i + 1`
		sleep 1
	done
fi
setprop dji.vision_service 1

# For debug
debuggerd&
mkdir -p /data/dji/log
mkdir -p /data/dji/cfg/test
# Auto save logcat to flash to help trace issues
if [ -f /data/dji/cfg/field_trail ]; then
	# Enable bionic libc memory leak/corruption detection
	setprop libc.debug.malloc 10
	# Up to 5 files, each file upto 32MB
	logcat -f /data/dji/log/logcat.log -r32768 -n4 *:I &
fi
# Capture temperature
#test_thermal.sh >> /data/dji/log/temperature.log &

if [ -f /data/dji/amt/state ]; then
	amt_state=`cat /data/dji/amt/state`
fi

# dump system/upgrade log to a special file
rm /data/dji/upgrade_log.tar.gz
upgrade_file_size=`busybox wc -c < /data/dji/log/upgrade00.log`
if [ $upgrade_file_size -gt 2097152 ]; then
mv /data/dji/log/upgrade07.log /data/dji/log/upgrade08.log
mv /data/dji/log/upgrade06.log /data/dji/log/upgrade07.log
mv /data/dji/log/upgrade05.log /data/dji/log/upgrade06.log
mv /data/dji/log/upgrade04.log /data/dji/log/upgrade05.log
mv /data/dji/log/upgrade03.log /data/dji/log/upgrade04.log
mv /data/dji/log/upgrade02.log /data/dji/log/upgrade03.log
mv /data/dji/log/upgrade01.log /data/dji/log/upgrade02.log
mv /data/dji/log/upgrade00.log /data/dji/log/upgrade01.log
else
echo -e "\n\n!!!new file start!!!\n">> /data/dji/log/upgrade00.log
fi
logcat -v threadtime |stdbuf -oL grep DUSS\&63 >> /data/dji/log/upgrade00.log &

env_amt_state=`env amt.state`
if [ "$env_amt_state"x == "factory_out"x ]; then
	cpld_dir=/data/dji/amt/factory_out/cpld
	mkdir -p $cpld_dir
	rm -rf $cpld_dir/log.txt
	local r=0
	local n=0
	while [ $n -lt 3 ]; do
		let n+=1
		test_fpga /dev/i2c-1 /dev/i2c-1 64 400000 /vendor/firmware/cpld.fw >> $cpld_dir/log.txt
		r=$?
		if [ $r == 0 ]; then
			env -d amt.state
			amt_state=factory_out
			echo factory > /data/dji/amt/state
			break
		fi
	done

	echo $r > $cpld_dir/result
fi

# kill dji_encoding when factory
if [ "$amt_state"x = "factory"x -o "$amt_state"x = "aging_test"x -o "$amt_state"x = "factory_out"x ]; then
	# kill encoding service
	setprop dji.factory_out 1
fi


if [ "$amt_state"x == "factory"x ]; then
	# Need to enable bootarea1 write for enc
	echo 0 > /sys/block/mmcblk0boot1/force_ro
fi

# Check whether do auto fs write test
if [ -f /data/dji/cfg/test/fs ]; then
	/system/bin/test_fs_write.sh
fi

# WIFI
# Check if usb wifi card is inserted
#RETRY_COUNT=1
#while [ $RETRY_COUNT -ge 0 ]
#do
#    busybox lsusb | grep 1022
#    if [ $? = 0 ]
#    then
#       setprop dji.network_service 1
#       break
#   else
#       echo "No wifi usb device" >> /data/dji/log/start_dji_system.log
#       busybox lsusb >> /data/dji/log/start_dji_system.log
#       sleep 1
#    fi
#    let RETRY_COUNT-=1
#done
# Check whether do auto sdr test
if [ $wl_link_type -ge 1 ]; then
	# enable ip forward for ip stack
	echo 1 > /proc/sys/net/ipv4/ip_forward
	# only enable forward for 192.168.41.2 RC and 192.168.41.3 GLASS
	/system/bin/iptables -A FORWARD -s 192.168.41.2 -d 192.168.41.3 -j ACCEPT
	/system/bin/iptables -A FORWARD -s 192.168.41.3 -d 192.168.41.2 -j ACCEPT
	# other ip could not be forword
	/system/bin/iptables -A FORWARD -i+ -j DROP
fi


if [ -f /data/dji/cfg/amt_sdr_test.cfg ]; then
	/system/bin/test_sdr.sh
else
	boardid=`cat /proc/cmdline | busybox awk '{for(a=1;a<=NF;a++) print $a}' | busybox grep board_id | busybox awk -F '=' '{print $2}'`
	if [ $wl_link_type -eq 0 ]; then
		# for baord ap004v2, gpio243 is wifi power control
		if [ "$boardid" = "0xe2200042" ]; then
			echo 243 > /sys/class/gpio/export
			echo 1 > /sys/class/gpio/gpio243/value
			sleep 0.2
		fi
		# hack for ssid=Maverick-xxx
		if [ -f /data/misc/wifi/hostapd.conf ]; then
			cp /data/misc/wifi/hostapd.conf /data/misc/wifi/hostapd.conf.back
			busybox sed -i -e 's|ssid=Maverick|ssid=Mavic|' /data/misc/wifi/hostapd.conf.back
			# hack for invalid psk
			if [ -f /amt/wifi.config ]; then
				cat /amt/wifi.config | grep psk
				if [ $? == 0 ]; then
					PSK=`cat /amt/wifi.config | grep psk | busybox awk -F '=' '{print $2}'`
					busybox sed -i "${line}s:wpa_passphrase=32ee9aa4:wpa_passphrase=$PSK:g" /data/misc/wifi/hostapd.conf.back
				fi
			fi
			mv /data/misc/wifi/hostapd.conf.back /data/misc/wifi/hostapd.conf
		fi
		# hack for invalid mar addr
		if [ -f /amt/WIFI_nvram.txt ]; then
			WIFI_NVRAM_SIZE=`busybox wc -c < /amt/WIFI_nvram.txt`
			if [ $WIFI_NVRAM_SIZE == 6 ]; then
				mount -o remount,rw /system
				sleep 1
				cp /amt/WIFI_nvram.txt /system/etc/firmware/ath6k/AR6004/hw3.0/softmac.bin
				sync
				mount -o remount,ro /system
			fi
		fi
		setprop dji.network_service 1
	else
		# for baord ap004v2, under sdr mode, wifi power shutdown, no load driver
		if [ "$boardid" != "0xe2200042" ]; then
			/system/bin/load_wifi_modules.sh
		fi
	fi
fi

# Here we update recovery.img since all the service should be started.
# We could make the recovery.img work before this script exit for some
# service not startup.
/system/bin/recovery_update.sh

env_boot_mode=`env boot.mode`
#no need do next steps in factory mode
if [ "$amt_state"x == "factory"x -o "$amt_state"x == "aging_test"x -o "$env_boot_mode"x == "factory_out"x ]; then
	env wipe_counter 0
	env crash_counter 0
	if [ "$amt_state"x == "aging_test"x ]; then
		echo "start aging_test..." > /dev/ttyS1
		/system/bin/aging_test.sh
	fi
	exit 0
fi

# for fatal errors, up to 32MB
logcat -v time -f /data/dji/log/fatal.log -r65536 -n1 *:F &
rm -rf /data/dji/log/fatal01.log
rm -rf /data/dji/log/fatal02.log
rm -rf /data/dji/log/fatal03.log

ps | grep dji_sys
if [ $? != 0 ];then
	echo "crash_counter: dji_sys not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_hdvt_uav
if [ $? != 0 ];then
	echo "crash_counter: dji_hdvt_uav not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_vision
if [ $? != 0 ];then
	echo "crash_counter: dji_vision not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_monitor
if [ $? != 0 ];then
	echo "crash_counter: dji_monitor not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_encoding
if [ $? != 0 ];then
	echo "crash_counter: dji_encoding not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

env wipe_counter 0
env crash_counter 0

# dump LC1860 state
check_1860_state.sh&

# panic and tombstones check
panic_tombstone_check.sh &

# dump wifi log
# wifi log will be output only when usb inserted
# and there is a wifi.debug file in usb root dir
/system/bin/wifi_debug.sh &
# dump profiled wifi log
/system/bin/wifi_profiled_debug.sh &

# Check whether do auto OTA upgrade test
if [ -f /data/dji/cfg/test/ota ]; then
	/system/bin/test_ota.sh
fi

# Check whether do auto reboot test
if [ -f /data/dji/cfg/test/reboot ]; then
	sleep 20
	reboot
fi
