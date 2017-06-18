#! /system/bin/sh

DMSG_SIZE=2097152
# Kernel log
echo -e "\n\n!!!New kernel log start!!!\n" >> /data/dji/log/kernel00.log
dmesg -c >> /data/dji/log/kernel00.log

while true
do
    dmesg -c >> /data/dji/log/kernel00.log
    kernel_logfile_size=`busybox wc -c < /data/dji/log/kernel00.log`
    if [ $kernel_logfile_size -gt $DMSG_SIZE ]; then
        mv /data/dji/log/kernel07.log /data/dji/log/kernel08.log
        mv /data/dji/log/kernel06.log /data/dji/log/kernel07.log
        mv /data/dji/log/kernel05.log /data/dji/log/kernel06.log
        mv /data/dji/log/kernel04.log /data/dji/log/kernel05.log
        mv /data/dji/log/kernel03.log /data/dji/log/kernel04.log
        mv /data/dji/log/kernel02.log /data/dji/log/kernel03.log
        mv /data/dji/log/kernel01.log /data/dji/log/kernel02.log
        mv /data/dji/log/kernel00.log /data/dji/log/kernel01.log
    fi
    sleep 5
done
