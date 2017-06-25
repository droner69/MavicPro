#$1	test_case_id
#$2	test_case_name
#$3	test_result
if [ $# -lt 3 ];then
	return 1
fi
dir="/data/dji/amt/factory_out/test_result"
test_time=`date "+%G%m%d%H%M%S"`
mkdir -p $dir
`rm -rf $dir/$1_$2*`
echo $3 > "$dir/$1_$2_$test_time"
sync
