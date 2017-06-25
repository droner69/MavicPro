#!/system/bin/sh

. lib_test_220rc.sh

# Check partitions, try format it and reboot when failed
/system/bin/part_check.sh

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
else
	cmdline=`cat /proc/cmdline`
	temp=${cmdline##*board_sn=}
	board=${temp%% *}
	in_whitelist.sh $board
	if [ $? == 0 ]; then
		debug=true
	fi
fi

if $debug; then
	/system/bin/adb_en.sh
else
	setprop sys.usb.config rndis,mass_storage,bulk,acm
fi

setprop dji.sdrs_log 1

# rndis
ifconfig rndis0 192.168.42.2

# WIFI
#ifconfig ra0 192.168.1.2

mkdir /var/lib
mkdir /var/lib/misc
echo > /var/lib/misc/udhcpd.lease
busybox udhcpd
# ftp server on rndis0 interface
busybox tcpsvd -vE 0 21 busybox ftpd -w /ftp &

#create folders for upgrading
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

#set max socket recv buffer size
busybox sysctl -w net.core.rmem_max=0x80000

# CP SDR channel
#dji_net.sh gnd &

#usbmuxd -v -v

# Start services
export HOME=/data
setprop dji.monitor_service 1
setprop dji.hdvt_service 1
setprop dji.system_service 1

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

#adb start-server


# kill dji_encoding when factory
if [ "$amt_state"x = "factory"x -o "$amt_state"x = "aging_test"x -o "$amt_state"x = "factory_out"x ]; then
	# kill encoding service
	setprop dji.factory_out 1
fi

if [ "$amt_state"x == "normal"x -o "$amt_state"x == ""x ]; then
	post_aging_test
fi

if [ "$amt_state"x == "factory"x ]; then
	# Need to enable bootarea1 write for enc
	echo 0 > /sys/block/mmcblk0boot1/force_ro
fi

# Check whether do auto fs write test
if [ -f /data/dji/cfg/test/fs ]; then
	/system/bin/test_fs_write.sh
fi

# Check whether do auto sdr test
if [ -f /data/dji/cfg/amt_sdr_test.cfg ]; then
	/system/bin/test_sdr.sh
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
		echo "start aging_test..." > /dev/ttyS3
		/system/bin/test_fan.sh 1
		/system/bin/aging_test.sh
	fi
	exit 0
fi

# for fatal errors, up to 32MB
setprop dji.logcat 1
rm -rf /data/dji/log/fatal01.log
rm -rf /data/dji/log/fatal02.log
rm -rf /data/dji/log/fatal03.log

ps | grep dji_sys
if [ $? != 0 ];then
	echo "crash_counter: dji_sys not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_hdvt_gnd
if [ $? != 0 ];then
	echo "crash_counter: dji_hdvt_gnd not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

ps | grep dji_monitor
if [ $? != 0 ];then
	echo "crash_counter: dji_monitor not exist" > /data/dji/log/crash_counter.log
	sync
	exit -1
fi

env wipe_counter 0
env crash_counter 0

# dump LC1860 state
check_1860_state.sh&

# panic and tombstones check
panic_tombstone_check.sh &

# dump profiled kernel log
/system/bin/kernel_profiled_debug.sh &

# Check whether do auto OTA upgrade test
if [ -f /data/dji/cfg/test/ota ]; then
	/system/bin/test_ota.sh
fi

mkdir -p /system/sound_for_rc

# Check whether do auto reboot test
if [ -f /data/dji/cfg/test/reboot ]; then
	sleep 20
	reboot
fi

if [ "$amt_state"x == "factory"x ]; then
	echo "in factory mode of normal.img!!!"
else
	config_soc_pwm0_for_fan.sh &
fi
