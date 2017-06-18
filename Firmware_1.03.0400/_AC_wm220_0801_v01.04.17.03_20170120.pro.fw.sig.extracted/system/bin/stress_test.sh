# usage:
# ./stress_test.sh [num_of_test_mem] [test_mem_size_per_instance]

# include the script lib
. lib_test_stress.sh

# memory test
num=$1
sz=$2
if [ -z $num ]; then num=4; fi
if [ -z $sz ]; then sz=0x200000; fi
start_inf_error_action $num "test_mem -s $sz -l 1000"

# compression test
dd if=/dev/urandom of=/tmp/testimage bs=524288 count=10
start_inf_error_action 4 "gzip -9 -c /tmp/testimage | gzip -d -c > /dev/null"

# codec
#log=/data/dji/log/test_multi_enc.log
#start_inf_error_action 1 "test_multi_enc 7 > $log"

# camera
#log=/data/dji/log/AP-308.log
#rm -rf $log
#start_inf 1 "cat /proc/buddyinfo >> $log && test_cam_hal -s camera-AP-308.cts >> $log && cat /proc/buddyinfo >> $log && sleep 5"

# gpu
#log=/data/dji/log/test_opencl_nr.log
#start_inf_error_action 1 "test_opencl_nr /system/bin/nr.cl /system/bin/test_1080p.yuv > $log"

if [ ${wireless_type} = "sdr" ]; then
# network test
#cp uav
start_inf_error_action 1 "test_cp_uav.sh"

# cp state test
start_inf_error_action 1 "modem_info.sh cps >> /data/dji/log/cp_state.log && sleep 1"
fi

