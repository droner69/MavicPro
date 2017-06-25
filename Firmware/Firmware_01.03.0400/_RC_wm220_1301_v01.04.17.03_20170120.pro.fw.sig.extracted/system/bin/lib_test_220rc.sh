LO_RANGE=0
MID_RANGE=1
HI_RANGE=2

fg_lo_th=65
fg_hi_th=75

random_less_than_5()
{
	a=$(($RANDOM%4))
	echo "random sleep for $a seconds..."
	return $(($a+1))
}

read_charger_reg()
{
	reg_val=`dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 5 -1 $1 | busybox awk 'END{print $2}'`
	ret=${PIPESTATUS[0]}
	while [ $ret -ne 0 ]; do
		random_less_than_5
		sleep $?
		reg_val=`dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 5 -1 $1 | busybox awk 'END{print $2}'`
		ret=${PIPESTATUS[0]}
		echo "retry to read battery reg_val..."
	done

	echo $reg_val
}

enable_charging()
{
	dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x4700
	ret=$?
	while [ $ret -ne 0 ]; do
		random_less_than_5
		sleep $?

		dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x4700
		ret=$?
		echo "retry to configure ilimit to 3A..."
	done

	dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x1b01
	ret=$?
	while [ $ret -ne 0 ]; do
		random_less_than_5
		sleep $?

		dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x1b01
		ret=$?

		echo "retry to enable charing..."
	done

	read_charger_reg 1
	read_charger_reg 0
}

disable_charging()
{
	dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x4000
	ret=$?
	while [ $ret -ne 0 ]; do
		random_less_than_5
		sleep $?

		dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x4000
		ret=$?
		echo "retry to configure ilimit to 100mA..."
	done

	dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x0b01
	ret=$?
	while [ $ret -ne 0 ]; do
		random_less_than_5
		sleep $?

		dji_mb_ctrl -R diag -g 6 -t 0 -s 9 -c 4 -2 0x0b01
		ret=$?
		echo "retry to enable charing..."
	done

	read_charger_reg 1
	read_charger_reg 0
}

get_rc_capacity()
{
	logcat -d | grep cur_cap | busybox tail | busybox awk -F "=" 'END{print $2}' | busybox awk -F "," '{print $1}' | busybox sed 's/^\s//g'
}

post_aging_test()
{
	reg_val=`read_charger_reg 0`
	echo "reg0 = $reg_val"

	reg_val=`read_charger_reg 1`
	echo "reg1 = $reg_val"

	if [ "$reg_val" != "1b" ]; then
		enable_charging
		echo "enable charging..."
	else
		echo "charing is enabled by default."
	fi
}
