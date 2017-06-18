#!/system/bin/sh

echo; echo; echo "Start to capture 1860/A9/PA temperature"
seq_id=0
while true; do
    let seq_id+=1
    sleep 10
    echo; echo -n `date`

    # Get 1860 thermal
    TEMPERATURE_1860=`cat /proc/driver/comip-thermal | grep 'last is' | busybox awk '{ print $15; }'`
    busybox printf " 1860 temperature: %03d, " $TEMPERATURE_1860

    # Get A9 thermal
    RESP_MSG_A9_RAW=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c 54 -1 0 -q $seq_id`
    if [ $? -ne 0 ]; then
        continue
    fi
    RESP_MSG_A9=`echo "$RESP_MSG_A9_RAW" | busybox sed -n 4p`
    RESP_RESULT_A9=$((16#`echo $RESP_MSG_A9 | busybox awk '{ print $1; }'`))
    TEMPERATURE_A9_LOW=$((16#`echo $RESP_MSG_A9 | busybox awk '{ print $2; }'`))
    TEMPERATURE_A9_HIGH=$((16#`echo $RESP_MSG_A9 | busybox awk '{ print $3; }'`))
    let TEMPERATURE_A9=$TEMPERATURE_A9_HIGH*256+$TEMPERATURE_A9_LOW
    busybox printf "A9 temperature: %03d, " $TEMPERATURE_A9

    # Get PA thermal
    RESP_MSG_PA_RAW=`dji_mb_ctrl -S test -R local -g 9 -t 0 -s 0 -c 54 -1 0`
    if [ $? -ne 0 ]; then
        continue
    fi
    RESP_MSG_PA=`echo "$RESP_MSG_PA_RAW" | busybox sed -n 4p`
    RESP_RESULT_PA=$((16#`echo $RESP_MSG_PA | busybox awk '{ print $1; }'`))
    TEMPERATURE_PA_LOW=$((16#`echo $RESP_MSG_PA | busybox awk '{ print $2; }'`))
    TEMPERATURE_PA_HIGH=$((16#`echo $RESP_MSG_PA | busybox awk '{ print $3; }'`))
    let TEMPERATURE_PA=$TEMPERATURE_PA_HIGH*256+$TEMPERATURE_PA_LOW
    busybox printf "PA temperature: %03d" $TEMPERATURE_PA
done
