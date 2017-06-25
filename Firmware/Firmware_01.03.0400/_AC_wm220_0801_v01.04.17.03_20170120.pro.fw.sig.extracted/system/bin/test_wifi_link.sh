/system/bin/antenna_switch.sh WIFI
tcpdump -i any -s 256 -w /data/dji/amt/wifi_link_test.pcap 1>/dev/null&
test_wifi.sh $1 $2 $3 1>/tmp/test_wifi_link
kill -9 $(busybox pidof tcpdump)
grep "PASSED" /tmp/test_wifi_link
ret=$?
cat /tmp/test_wifi_link
if [ $ret -ne 0 ];then
	exit 1
else
	exit 0
fi
