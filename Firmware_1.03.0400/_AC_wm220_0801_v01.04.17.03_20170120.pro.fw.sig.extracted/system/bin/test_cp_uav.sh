#!/system/bin/sh

mkdir -p /data/dji/log
mount -o remount,rw /system
echo `date` > /data/dji/log/cp_test.result
busybox httpd -p 8081 -h /
test_cp

