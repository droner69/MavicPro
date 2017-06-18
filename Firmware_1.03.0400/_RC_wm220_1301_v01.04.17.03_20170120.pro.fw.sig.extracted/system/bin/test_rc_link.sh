#para1
#1 vibrator
#2 speaker
#3 lcd
#4 speaker 2KHz
#5 speaker 100Hz

case $1 in
    1)  echo "test vibrator"
	test_vibrator.sh
        ret=0
	;;
    2)  echo "test speaker"
	test_speaker.sh 1
        ret=0
	;;
    3)  echo "test lcd"
	test_rc_lcd.sh
        ret=0
	;;
    4)  echo "test speaker 2Khz"
	test_speaker.sh 2
        ret=0
	;;
    5)  echo "test speaker 100Hz"
	test_speaker.sh 3
        ret=0
	;;
    *)  echo 'You do not input a right key index between 1~3'
	echo "1: test vibrator"
	echo "2: test speaker"
	echo "3: test lcd"
	echo "3: test speaker 2KHz"
	echo "3: test speaker 100Hz"
	ret=1
	;;
esac

exit $ret
