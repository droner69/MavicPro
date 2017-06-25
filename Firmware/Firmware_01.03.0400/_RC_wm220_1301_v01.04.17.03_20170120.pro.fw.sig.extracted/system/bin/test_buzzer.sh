#$1
#0 disable buzzer
#1 enable the 1st frequency
#2 enable the 2nd frequency
#3 enable the 3rd frequency

if [ $# -eq 2 ]; then
	id=$2
else
	id=0
fi

case $1 in
    0)  echo "disable buzzer"
	value_for_buzzer=00000000000000
	;;
    1)  echo "1st frequency"
	value_for_buzzer=00020000000000
	;;
    2)  echo "2nd frequency"
	value_for_buzzer=00040000000000
	;;
    3)  echo "3rd frequency"
	value_for_buzzer=00060000000000
	;;
    *)  echo 'You do not input a right key index between 1~3'
	echo '1 for 1st frequency'
	echo '2 for 2nd frequency'
	echo '3 for 3rd frequency'
	value_for_buzzer=00000000000000
	exit 1
	;;
esac

dji_mb_ctrl -R diag -g 6 -t $id -s 6 -c f7 -a 0 -7 $value_for_buzzer

exit 0
