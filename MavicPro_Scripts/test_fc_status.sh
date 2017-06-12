result=`dji_mb_ctrl -S test -R diag -g 3 -t 6 -s 0 -c 4c`
if [ $? != 0 ];then
	if [ $# == 2 ] && [ $2 == "aging_test" ];then
		echo "aging test cmd error $?, please check fly control version and connection!!!"
		exit 0
	else
		echo "cmd error $?, please check fly control version and connection!!!"
		exit 1
	fi
fi
echo $result
raw_data=${result##*data:}
bytes=`echo $raw_data | busybox awk '{printf $5$4$3$2;}'`
echo "0x$bytes"

if [ $1 == "pre_aging_test" ];then
	flag=0
	for i in {8,9,10,11,13,16,18}
	do
		bitmask=$((1 << $i))
		bit_result=$((16#$bytes&$bitmask))
		if [ $bit_result == 0 ]; then
        		echo "bit $i is not set"
		else
			flag=1
        		echo "bit $i is set, the module error!!!!"
		fi
	done
	if [ 0 == $flag ];then
		exit 0
	else
		exit 1
	fi
fi

bitmask=$((1 << $1))
bit_result=$((16#$bytes&$bitmask))
if [ $bit_result == 0 ]; then
	echo "bit $1 is not set"
	exit 0
else
	echo "bit $1 is set, the module error!!!!"
	exit 1
fi
