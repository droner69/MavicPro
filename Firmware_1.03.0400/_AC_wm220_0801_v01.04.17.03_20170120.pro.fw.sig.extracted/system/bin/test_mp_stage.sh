mkdir -p /data/dji/amt

if [ -z $3 ];then
	echo test_mp_stage.sh $1 $2
else
	echo test_mp_stage.sh $1 $2 $3
fi

if [ "normal"x != "$1"x -a "factory"x != "$1"x -a "aging_test"x != "$1"x -a "single_aging_test"x != "$1"x -a "erase"x != "$1"x ]; then
	echo "You input test_mp_stage.sh $1, please input a right para!"
	echo "Failure, should be normal, factory or aging_test, thanks!"
	exit 1;
else
	echo "You input test_mp_stage.sh $1."
	echo "$1" > /data/dji/amt/state

	if [ `env -g board | busybox grep -wc WM220_RP_V4` -eq 1 ]; then
		. lib_test_220rc.sh
		if [ "$1"x == "normal"x ]; then
			post_aging_test
		fi
	fi

	sync

	if [ "aging_test"x == "$1"x -o "single_aging_test"x == "$1"x ]; then
		env -d boot.mode
	fi

	local stat=`cat /data/dji/amt/state`
	if [ "$1"x == "aging_test"x -o "single_aging_test"x == "$1"x ] && [ $# == 2 ]; then
		echo $2 > /data/dji/amt/aging_test_timeout
	fi

	if [ "$1"x == "aging_test"x -o "single_aging_test"x == "$1"x ] && [ $# == 3 ]; then
		echo $2 > /data/dji/amt/aging_test_timeout
		echo $3 > /data/dji/amt/aging_test_modules
	fi

	if [ "$1"x == "erase"x ]; then
		env -d boot.mode
		echo factory > /data/dji/amt/state
		sync
		exit 0
	fi

	sync

	if [ "$1"x != "$stat"x ]; then
		echo "Failure, should get $1, but get $stat."
		exit 1
	else
		echo "Success"
	fi

fi
