mount -o remount,rw /amt
mount -o remount,rw /system
sleep 1

#AMT file path
AMT_FILE=/amt/WIFI_nvram.txt
#Softmac file path
SOFTMAC_FILE=/system/etc/firmware/ath6k/AR6004/hw3.0/softmac.bin
#Return value
RETVAL=0

# Parameters validation
if [ -z "$1" -o -z "$2" ]
then
    echo "Usage"
    echo "write: \"1\" \"\\\xAA\\\xBB\\\xCC\\\xDD\\\xEE\\\xFF\""
    echo "check: \"0\" \"\\\xAA\\\xBB\\\xCC\\\xDD\\\xEE\\\xFF\""
    exit 1
fi

# Ops checking
if [ -f "$AMT_FILE" ]
then
   echo "Update $AMT_FILE"
   rm $AMT_FILE
fi

if [ "$1" = "1" ]
then
    echo "write mac addr"
    if [ -f "$SOFTMAC_FILE" ]
    then
       echo "Update $SOFTMAC_FILE"
       rm $SOFTMAC_FILE
    fi
    echo -n -e $2 > $AMT_FILE
    echo -n -e $2 > $SOFTMAC_FILE
else
    echo "check mac addr"
    echo -n -e $2 > $AMT_FILE
    busybox diff $AMT_FILE $SOFTMAC_FILE
    if [ $? = 0 ]
    then
        echo "mac addr checking success"
        RETVAL=0
    else
        echo "mac addr checking failed"
        RETVAL=-1
    fi
fi
sync
mount -o remount,ro /amt
mount -o remount,ro /system
/system/bin/test_wifi_init.sh 1 > /dev/null &
exit $RETVAL
