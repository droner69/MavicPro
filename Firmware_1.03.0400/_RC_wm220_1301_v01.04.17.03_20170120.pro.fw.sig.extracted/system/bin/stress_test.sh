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
log=/data/dji/log/test_multi_enc.log
start_inf_error_action 1 "test_multi_enc 7 > $log"

#cp gnd
start_inf_error_action 1 "test_cp_gnd.sh"

# cp state test
start_inf_error_action 1 "modem_info.sh cps >> /data/dji/log/cp_state.log && sleep 1"
