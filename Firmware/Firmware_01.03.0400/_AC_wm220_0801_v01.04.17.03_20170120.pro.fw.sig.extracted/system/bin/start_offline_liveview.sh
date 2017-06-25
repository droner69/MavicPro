#wm220 offine liveview quality test

#****NOTCE****
#Please disconnect usb from 1860 upon this script start
#The SDCard should only contain video

ret=0 # ignore
seq_num=0 # ignore
i=0 #ignore

video_count=5 # total video number
circle=1000 # the number of all video should be played
sleep_time=30 # time of each video be played, unit:second

start_index=0x0001863D # first file index(99901)
current_index=$start_index # ignore
temp_index=$start_index # ignore
let end_index=start_index+video_count # ignore

result_parser()
{
	#echo $1
	#echo $2

	res=`echo $2 | busybox awk '{print $NF}'`
	if [ $1 -ne 0 -o "$res" != "00" ]; then
		return 1
	else
		return 0
	fi
}

#sleep 5s to wait a9 ready
echo "offline liveview start, please disconnect usb from 1860!"
sleep 5

echo "start entry offline liveview mode"
ret=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c FF -q $seq_num -a 40 -1 1`
result_parser $? "$ret"
if [ $? -ne 0 ]; then
	echo "entry offline liveview mode fail"
	exit 1
else
	echo "entry offline liveview mode success"
fi

let seq_num+=1
echo "start entry video mode"
ret=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 10 -q $seq_num -a 40 -1 1`
result_parser $? "$ret"
if [ $? -ne 0 ]; then
	echo "entry video mode fail"
	exit 1
else
	echo "entry video mode success"
fi

let seq_num+=1
echo "start entry playback mode"
ret=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 10 -q $seq_num -a 40 -1 2`
result_parser $? "$ret"
if [ $? -ne 0 ]; then
	echo "entry playback mode fail"
	exit 1
else
	echo "entry playback mode success"
fi

echo "start liveview"
while [ $i -lt $circle ]; do
	current_index=$start_index
	temp_index=$(($current_index))
	while [ $temp_index -lt $end_index ]; do
		let seq_num+=1
		ret=`dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 7B -q $seq_num -a 40 -4 $current_index`
		result_parser $? "$ret"
		if [ $? -ne 0 ]; then
			echo "$current_index play fail, play next..."
		else
			echo "start play $current_index $sleep_time second..."
			sleep $sleep_time
		fi

		let seq_num+=1
		dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 7A -q $seq_num -a 40 -5 0
		let current_index+=1
		case $current_index in
			99902 ) current_index=0x0001863E;;
			99903 ) current_index=0x0001863F;;
			99904 ) current_index=0x00018640;;
			99905 ) current_index=0x00018641;;
			99906 ) current_index=0x00018642;;
			99907 ) current_index=0x00018643;;
			99908 ) current_index=0x00018644;;
			99909 ) current_index=0x00018645;;
			* ) current_index=0x0001863D;;
		esac
		temp_index=$(($current_index))
	done
	let i+=1
done

exit 1
