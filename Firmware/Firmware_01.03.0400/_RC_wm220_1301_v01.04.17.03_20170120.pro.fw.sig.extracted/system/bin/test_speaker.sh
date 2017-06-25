#$1
#0 stop playing
#1 SoundTest.wav
#2 2KHz
#3 100Hz

stop_file=/tmp/stop_playing_music
cnt=0

if [ $# -ne 2 ]; then
    times=1
else
    times=$2
fi

rm -rf $stop_file
case $1 in
	0) echo "stop audio playing"
		touch $stop_file
		sleep 1
		kill -9 $(busybox pidof tinyplay) 1>/dev/null 2>&1
		exit 0
		;;
	1)  echo "test SoundTest.wav"
		test_audio=/system/bin/SoundTest.wav
		;;
	2)  echo "test 2KHz"
		test_audio=/system/bin/2KHz.wav
		;;
	3)  echo "test 100Hz"
		test_audio=/system/bin/100Hz.wav
		;;
	*)  echo 'You do not input a right key index between 1~3'
		echo '0 stop playing'
		echo '1 SoundTest.wav'
		echo '2 2KHz.wav'
		echo '3 100Hz.wav'
        exit 1
		;;
esac
echo $test_audio

while [ $cnt -lt $times ]; do
	if [ -f $stop_file ]; then
		echo "$stop_file has been created."
		kill -9 $(busybox pidof tinyplay) 1>/dev/null 2>&1
		exit 0
	fi
	echo "playing $test_audio ..."
	tinyplay $test_audio
	cnt=$(($cnt+1))
done

echo "exit from this script...."
exit 0
