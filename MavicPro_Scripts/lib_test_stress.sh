. lib_test.sh

error_action()
{
	echo ----------------- disable auto-reboot test -------------------
	rm -rf /data/dji/cfg/test/reboot

	echo ----------------- last test app log --------------------
	testlogs=`ls /data/dji/log/test_*`
	for file in $testlogs
	do
		echo ------------------- $file ------------------
		cat $file
	done

	echo ----------------- memleak --------------------
	cat /sys/kernel/debug/kmemleak

	echo ----------------- thread info --------------------
	top -t -n 1

	echo ----------------- disk usage --------------------
	df
	du /data

	echo ----------------- tombstones --------------------
	tombstones=`ls /data/tombstones`
	for file in $tombstones
	do
		echo ------------------- $file ------------------
		cat /data/tombstones/$file
	done

	echo ----------------- dmesg --------------------
	dmesg

	echo ------------------ logcat -------------------------
	cat /data/dji/log/logcat.log.2
	cat /data/dji/log/logcat.log.1
	cat /data/dji/log/logcat.log

	reboot
}

#
# test preparation
# - clean previous log messages
# - execute some common scripts
#
mkdir -p /data/dji/log
rm -rf /data/tombstone

mount -t debugfs none /sys/kernel/debug
# for field_trail case, it already start logcat logging, do NOT do again
if [ ! -f /data/dji/cfg/field_trail ]; then
	# Up to 3 files, each file upto 100MB
	logcat -f /data/dji/log/logcat.log -r102400 -n2 *:I &
fi

. lib_env.sh
