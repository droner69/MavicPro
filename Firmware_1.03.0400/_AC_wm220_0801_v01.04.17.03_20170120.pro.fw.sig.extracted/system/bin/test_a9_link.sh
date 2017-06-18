#A9 link test
ret_val=0
#$1 testid, $2 seq_id $3 test_name
a9_link_test()
{
	#echo $1
	#echo $2
	#echo $3

	n=0
	echo "---------------- test a9 $3 start ---------------"
	while [ $n -lt 3 ]; do
		result=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c F4 -3 $1 -q $2`
		echo $result > /tmp/a9_link_result
		cat /tmp/a9_link_result
		let n+=1
		grep "00 00 00 00 00 00 00" /tmp/a9_link_result
		if [ $? -eq 0 ];then
			echo "test a9 $3 pass"
			echo
			echo
			return
		else
			continue
		fi
	done

	ret_val=1

	grep -rn "00 00 00 00 00 01 00" /tmp/a9_link_result
	if [ $? -eq 0 ];then
		echo "test a9 $3 fail"
	else
		echo "test a9 $3 timeout"
	fi
	echo
	echo
}

# check YUV test pattern
echo "---------------- test a9 YUV start ---------------"
dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c F4 -1 1b -q 7
test_encoding
if [ $? -ne 0 ]; then
	echo A9 check pattern fail
	ret_val=1
else
	echo A9 check pattern pass
fi
dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 0 -c F5 -1 1b -q 8

# sdcard 20=0x14
a9_link_test 14 1 sdcard

#image_sensor 21=0x15
a9_link_test 161715 5 image_sensor

#gimbal 22=0x16
a9_link_test 16 6 gimbal

# emcrypt sensor 24=0x18
a9_link_test 18 2 Emcrypt_sensor

# RTC 25=0x19
a9_link_test 19 3 RTC

#temp_sensor 26=0x1a
a9_link_test 1a 4 temp_sensor

exit $ret_val
