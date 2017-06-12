#$1	test_case_id
#$2	test_case_name
if [ $# == 0 ];then
	return 1
fi

dir="/data/dji/amt/factory_out/test_result"
result=`cat $dir/$1* | busybox tail -n 1`
echo "SMT test $1 $2 result: $result"
if [ "PASS" == $result ];then
	ret=0
else
	ret=1
fi

return $ret
