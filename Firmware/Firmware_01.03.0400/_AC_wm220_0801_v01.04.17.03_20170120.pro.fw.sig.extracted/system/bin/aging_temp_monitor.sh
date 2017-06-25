#!/system/bin/sh
amt=/data/dji/amt
dir=$amt/aging_test
aging_temp_max=112

temp=`grep "last is" /proc/driver/comip-thermal | busybox awk -F "," '{print $3}' | busybox awk '{print $3}'`

if [ $temp -gt $aging_temp_max ];then
	echo $temp > $dir/temperature
	sync
	echo "failed! temp is $temp, higher than $aging_temp_max!"
	exit 3
else
	exit 0
fi
