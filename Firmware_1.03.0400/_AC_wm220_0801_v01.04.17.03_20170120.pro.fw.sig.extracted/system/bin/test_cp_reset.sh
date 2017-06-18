#!/system/bin/sh
#This script is for test cp reset
fail_num=0
for i in `busybox seq 1 10000`; do
    echo "time $i fail_num $fail_num"
    #test_sdrs_prereset
    #busybox devmem 0xe007ff17 8 0
    #busybox devmem 0xe007ff20 32 0
    #busybox devmem 0xe007ff24 32 0
    sdrs_log_cmd modem 2
    j=0
    while true; do
        result=`busybox devmem 0xe007ff17 8`
        boot=`busybox devmem 0xe007ff20 32`
        boot2=`busybox devmem 0xe007ff24 32`
        j=$((j+1))
        if [ $result != "0x55" ]; then
            if [ $j -lt 11 ]; then
                sleep 1
            else
                echo "cp reboot failed $boot $boot2"
                modem_info.sh cps
                sleep 1
                modem_info.sh cps
                fail_num=$((fail_num+1))
                #break
                exit -1
            fi
        else
            echo success
            sleep 0.2
            modem_info.sh cps
            sleep 1
            modem_info.sh cps
            break
        fi
    done
done
