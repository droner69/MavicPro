. lib_test.sh

# set direction $2 to gpio $1
# example: set "out" to gpio165
#    gpio_set_dir 165 out
gpio_set_dir()
{
	local gpio=/sys/class/gpio/gpio$1
	if [ ! -d $gpio ]; then
		echo $1 > /sys/class/gpio/export
	fi
	local dir=`cat $gpio/direction`
	# note 1: after test, for output, must set direction first,
	#         otherwise, will get wrong output
	# note 2: if already set direction as "out", then do NOT set
	#         it again, otherwise, will get wrong output
	if [ "$2"x != "$dir"x ]; then
		echo $2 > $gpio/direction
	fi
}

# write value $2 to gpio $1
# example: write "1" to gpio165
#    gpio_write 165 1
gpio_write()
{
	gpio_set_dir $1 out
	local gpio=/sys/class/gpio/gpio$1
	echo $2 > $gpio/value
}

# read from gpio $1
# example: read from gpio165
#    gpio_read 165
gpio_read()
{
	gpio_set_dir $1 out
	local gpio=/sys/class/gpio/gpio$1
	cat $gpio/value
}

# send command
#   $1: receiver type
#   $2: receiver index
#   $3: cmd set
#   $4: cmd id
#   $5: hex data
# example:
#    send_cmd 12 0 0 2 deadbeef
send_cmd()
{
	dji_mb_ctrl -S test -R diag -g $1 -t $2 -s $3 -c $4 $5
}

# check version with recever type($1) & index($2)
# return 0 if succeed to get version, others if failed
# example: check link path with flyctrl (0300)
#    cmd_check_ver flyctrl 3 0 || return $?
cmd_check_ver()
{
	send_cmd $2 $3 0 1
	local r=$?
	if [ $r == 0 ]; then
		echo cmd_check_ver\($1\): PASSED
	else
		sleep 1
		send_cmd $2 $3 0 1
		r=$?
		if [ $r == 0 ]; then
			echo cmd_check_ver\($1\): FIRST FAILED, SECOND PASSED
			echo cmd_check_ver\($1\): FIRST FAILED, SECOND PASSED >> $dir/warning
		else
			echo cmd_check_ver\($1\): FIRST FAILED, SECOND FAILED, errno=$r
			echo cmd_check_ver\($1\): FIRST FAILED, SECOND FAILED, errno=$r >> $dir/warning
		fi
	fi
	return $r
}

cmd_check_ver_without_try()
{
	send_cmd $2 $3 0 1
	local r=$?
	if [ $r == 0 ]; then
		echo cmd_check_ver\($1\): PASSED
	else
		echo cmd_check_ver\($1\): FAILED, errno=$r
	fi
	return $r
}
