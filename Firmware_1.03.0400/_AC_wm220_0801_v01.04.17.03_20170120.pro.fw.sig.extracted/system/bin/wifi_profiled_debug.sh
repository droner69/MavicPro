#! /system/bin/sh

### BEGIN INFO
# Used to capture profiled wifi log
# ath6kl_usb device.
# Provides:    Gannicus Guo
### END INFO

kill_sync()
{
    echo "Request to kill: $1"
    kill -9 $1
    ps $1 | grep "logcat"
    while [ $? == 0 ]
    do
        ps $1 | grep "logcat"
        if [ $? != 0 ]
        then
            echo "target process: $1 killed"
            break
        else
            kill -9 $1
            sleep 0.1
        fi
    done
}

FILE_SIZE=2097152
DMSG_SIZE=2097152
#FILE_SIZE=1024
# Kernel log
echo -e "\n\n!!!New kernel log start!!!\n" >> /data/dji/log/kernel00.log
dmesg -c >> /data/dji/log/kernel00.log

# Wifi log
echo -e "\n\n!!!New file start!!!\n" >> /data/dji/log/wifi00.log
logcat -v threadtime | grep -e DUSS\&5c -e hostapd >> /data/dji/log/wifi00.log &
JOBPPID=$$
while true
do
    wifi_logfile_size=`busybox wc -c < /data/dji/log/wifi00.log`
    if [ $wifi_logfile_size -gt $FILE_SIZE ]; then
        LOGCATPID=`busybox pgrep -l -P ${JOBPPID} | grep logcat | busybox awk '{print $1}'`
        echo "Kill current job: ${LOGCATPID}" >> /data/dji/log/wifi00.log
#the grep process automatically exit after killing logcat
        kill_sync $LOGCATPID
        mv /data/dji/log/wifi07.log /data/dji/log/wifi08.log
        mv /data/dji/log/wifi06.log /data/dji/log/wifi07.log
        mv /data/dji/log/wifi05.log /data/dji/log/wifi06.log
        mv /data/dji/log/wifi04.log /data/dji/log/wifi05.log
        mv /data/dji/log/wifi03.log /data/dji/log/wifi04.log
        mv /data/dji/log/wifi02.log /data/dji/log/wifi03.log
        mv /data/dji/log/wifi01.log /data/dji/log/wifi02.log
        mv /data/dji/log/wifi00.log /data/dji/log/wifi01.log
        logcat -v threadtime | grep -e DUSS\&5c -e hostapd >> /data/dji/log/wifi00.log &
        echo "New wifi job" >> /data/dji/log/wifi00.log
    fi
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
