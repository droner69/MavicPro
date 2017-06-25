#!/system/bin/sh

#mount -o remount,rw /system
#if [ ! -e /system/bin/start_dji_system.sh.bak ]; then
#    cp /system/bin/start_dji_system.sh /system/bin/start_dji_system.sh.bak
#    echo "busybox httpd -p 8081" >> /system/bin/start_dji_system.sh
#    echo "test_cp.sh &" >> /system/bin/start_dji_system.sh
#    sync
#    reboot
#fi

mkdir -p /data/dji/log

#kill dji_hdvt_uav
process_name="dji_hdvt_gnd"
process_id=`busybox pgrep -f $process_name`
if [ -n $process_id ]; then
    kill $process_id
fi
echo "$thiscasestep: kill $process_name" >> /data/dji/log/cp_test.result

#==============================================================================
#test_id 1
#This test case is to test download speed without video transfer
thiscasestep="test_id 1 step_id 1"

echo `date` > /data/dji/log/cp_test.result
test_cp 1 1
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
cd /data
timea=`date +%s`
busybox wget http://192.168.41.1:8080/data/100M
timeb=`date +%s`

thiscasestep="test_id 1 step_id 2"
test_cp 1 2

speed=`echo $timea $timeb |busybox awk '{printf "%f\n", 100.0 / ($2 - $1)}'`
echo "$thiscasestep: without video transfer download speed $speed MB/s" >> /data/dji/log/cp_test.result
rm /data/100M

echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
#end

#==============================================================================
#test_id 2
#This test case is to test download speed without video transfer
thiscasestep="test_id 2 step_id 1"
test_cp 2 1
test_wlc -t sdp &
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result

thiscasestep="test_id 2 step_id 2"
test_cp 2 2
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
cd /data
timea=`date +%s`
busybox wget http://192.168.41.1:8080/data/100M
timeb=`date +%s`

thiscasestep="test_id 2 step_id 3"
test_cp 2 3

speed=`echo $timea $timeb |busybox awk '{printf "%f\n", 100.0 / ($2 - $1)}'`
echo "$thiscasestep: with video transfer download speed $speed MB/s" >> /data/dji/log/cp_test.result
rm /data/100M

echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
#end

#==============================================================================
#test_id 3
#This test case is to test dmp speed without video transfer
test_cp 3 1
thiscasestep="test_id 3 step_id 1"
test_dmp -w -m 0
sleep 5

#==============================================================================
#test_id 3
#This test case is to test dmp speed without video transfer
test_cp 3 2
thiscasestep="test_id 3 step_id 2"

busybox wget http://192.168.41.1:8081/tmp/dmp_result -O /tmp/dmp_result
result=`cat /tmp/dmp_result`

echo "$thiscasestep: $result" >> /data/dji/log/cp_test.result
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
#end

#==============================================================================
#test_id 4
#This test case is to test dmp speed without video transfer
test_cp 4 1
thiscasestep="test_id 4 step_id 1"
test_dmp -w -m 1
sleep 5

#==============================================================================
#test_id 4
#This test case is to test dmp speed without video transfer
test_cp 4 2
thiscasestep="test_id 4 step_id 2"

busybox wget http://192.168.41.1:8081/tmp/dmp_result -O /tmp/dmp_result
result=`cat /tmp/dmp_result`

echo "$thiscasestep: $result" >> /data/dji/log/cp_test.result
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
#end

#==============================================================================
#test_id 5
#This test case is to test dmp speed without video transfer
test_cp 5 1
thiscasestep="test_id 5 step_id 1"
test_dmp -w -m 2
sleep 5

#==============================================================================
#test_id 5
#This test case is to test dmp speed without video transfer
test_cp 5 2
thiscasestep="test_id 5 step_id 2"

busybox wget http://192.168.41.1:8081/tmp/dmp_result -O /tmp/dmp_result
result=`cat /tmp/dmp_result`

echo "$thiscasestep: $result" >> /data/dji/log/cp_test.result
echo "$thiscasestep: done" >> /data/dji/log/cp_test.result
#end

cat /data/dji/log/cp_test.result

#==============================================================================
#test_id 4
#This test case is to test sdr long time by iperf
test_cp 6 1

echo "begin iperf long time test"
iperf -c 192.168.41.1 &> /dev/null

#end
