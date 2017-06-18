#!/system/bin/sh

if [ $# -eq 2 ]; then
	host=$1
	id=$2
else
	host=6
	id=0
fi

result_raw=`dji_mb_ctrl -R diag -g $host -t $id -s 6 -c 27`
echo $result_raw > /tmp/test_mcu_link.log
cat /tmp/test_mcu_link.log
grep "00 3c 00" /tmp/test_mcu_link.log
if [ $? == 0 ];then
	exit 0
else
	result=`echo $result_raw| busybox awk '{ print $21; }'`;echo $result
	result=$((16#${result}))
	bit_result5=`echo $((result & 16#20))`
	bit_result4=`echo $((result & 16#10))`
	bit_result3=`echo $((result & 8))`
	bit_result2=`echo $((result & 4))`

	if [ $bit_result2 == 0 ];then
		echo "charger feature error"
	fi
	if [ $bit_result3 == 0 ];then
		echo "power key error"
	fi
	if [ $bit_result4 == 0 ];then
		echo "fuel gauge error"
	fi
	if [ $bit_result5 == 0 ];then
		echo "charger access error"
	fi
	exit 1
fi
