#para1
#1 home(left-upper corner)			event2: 0001 0106 00000001	|	event2: 0001 0106 00000000
#2 emergency(left-down corner of lcd)		event2: 0001 0105 00000001	|	event2: 0001 0105 00000000
#3 5D up					event2: 0001 0100 00000001	|	event2: 0001 0100 00000000
#4 5D down					event2: 0001 0104 00000001	|	event2: 0001 0104 00000000
#5 5D left					event2: 0001 0102 00000001	|	event2: 0001 0102 00000000
#6 5D right					event2: 0001 0103 00000001	|	event2: 0001 0103 00000000
#7 5D press					event2: 0001 0101 00000001	|	event2: 0001 0101 00000000
#8 left joystick				event3: 0003 0001 ffffffb3
#9 right joystick				event5: 0003 0001 fffffe27
#10 shutter(right corner)			event2: 0001 00d4 00000001	|	event2: 0001 00d4 00000000
#11 record(left corner)				event2: 0001 0189 00000001	|	event2: 0001 0189 00000000
#12 c1						event2: 0001 0069 00000001	|	event2: 0001 0069 00000000
#13 c2						event2: 0001 006a 00000001	|	event2: 0001 006a 00000000
#14 gimbal pitch				event0: 0003 0000 00000072
#15 iso						event1: 0003 0001 00000741
#16 lock					event2: 0001 0107 00000001	|	event2: 0001 0107 00000000
#17 power_key

key_dump=/tmp/rc_key_event.log
# $1 pattern1
# $2 pattern2
check_key_state()
{
	local ret_value=0
#echo $1
	grep "$1" $key_dump 1>/dev/null 2>/dev/null
	ret_value=$?
	return $ret_value
}
echo test key index $1

ret=1

case $1 in
    1)  echo 'Check Home key'
        check_key_state "event2: 0001 0106 00000001"
        ret=$?
	;;
    2)  echo 'Check emergency key'
	check_key_state "event2: 0001 0105 00000001"
        ret=$?
	;;
    3)  echo 'Check 5D up key'
	check_key_state "event2: 0001 0100 00000001"
        ret=$?
	;;
    4)  echo 'Check 5D down key'
	check_key_state "event2: 0001 0104 00000001"
        ret=$?
	;;
    5)  echo 'Check 5D left key'
	check_key_state "event2: 0001 0102 00000001"
        ret=$?
	;;
    6)  echo 'Check 5D right key'
	check_key_state "event2: 0001 0103 00000001"
        ret=$?
	;;
    7)  echo 'Check 5D press key'
	check_key_state "event2: 0001 0101 00000001"
        ret=$?
	;;
    8)  echo 'Check left joystick key'
	check_key_state "event3"
        ret=$?
	;;
    9)  echo 'Check right joystick key'
	check_key_state "event5"
        ret=$?
	;;
    10) echo 'Check shutter key'
	check_key_state "event2: 0001 00d4 00000001"
        ret=$?
	;;
    11) echo 'Check record key'
	check_key_state "event2: 0001 0189 00000001"
        ret=$?
	;;
    12) echo 'Check C1 key'
	check_key_state "event2: 0001 0069 00000001"
        ret=$?
	;;
    13) echo 'Check C2 key'
	check_key_state "event2: 0001 006a 00000001"
        ret=$?
	;;
    14) echo 'Check gimbal pitch key'
	check_key_state "event0"
        ret=$?
	;;
    15) echo 'Check ISO key'
	check_key_state "event1"
        ret=$?
	;;
    16) echo 'Check lock key'
	check_key_state "event2: 0001 0107 00000001"
        ret=$?
	;;
    *)  echo 'You do not input a right key index between 1~16'
	ret=1
	;;
esac

exit $ret
