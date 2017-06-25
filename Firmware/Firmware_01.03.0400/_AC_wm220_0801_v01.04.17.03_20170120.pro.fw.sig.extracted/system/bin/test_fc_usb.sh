acmid=20
vidpid_dir=/data/amt/dji
vidpid=$vidpid_dir/vidpid

mkdir -p $vidpid_dir

if [ -f $vidpid ]; then
	rm $vidpid
fi

while [ $acmid -ge 0 ]
do
	local modalias=/sys/class/tty/ttyACM$acmid
	echo $modalias
	if [ ! -d $modalias ]; then
		echo "$modalias not exist"
	else
		local target=`grep vFFF0p0008 $modalias/device/modalias`
		echo "$target"
		if [ -n "$target" ]; then
			echo $target > $vidpid
		fi
	fi
	let acmid-=1
done

if [ -f $vidpid ]; then
	rm $vidpid
	exit 0
else
	exit 1
fi

