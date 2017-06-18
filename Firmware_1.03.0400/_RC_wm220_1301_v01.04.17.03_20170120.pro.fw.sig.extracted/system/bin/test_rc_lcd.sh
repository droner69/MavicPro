#no para, show full logo

#para1
#full: show full screen logo
#close: show null on screen
#aging_test: doing aging_test
#aging_pass: aging test pass
#aging_fail: aging test fail

if [ $# == 0 ];then
	dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 -1 2
	exit 0
fi

case $1 in
    "full")  echo "show full screen"
		dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 -1 2
        ret=0
	;;
    "close")  echo "show nothing"
		dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 -1 1
        ret=0
	;;
    "aging_test")  echo "show aging_test"
		dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 00000000000000000000000000000000000000000000000000000000004147494E472D54455354200000
        ret=0
	;;
    "aging_pass")  echo "show aging_pass"
		dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 00000000000000000000000000000000000000000000000000000000004147494E472D50415353200000
        ret=0
	;;
    "aging_fail")  echo "show aging_fail"
		dji_mb_ctrl -R diag -g 6 -t 0 -s 6 -c 52 00000000000000000000000000000000000000000000000000000000004147494E472D4641494C200000
        ret=0
	;;
    *)  echo 'You do not input a right parameter'
	echo "full"
	echo "close"
	echo "aging_test"
	echo "aging_pass"
	echo "aging_fail"
	ret=1
	;;
esac

exit $ret
