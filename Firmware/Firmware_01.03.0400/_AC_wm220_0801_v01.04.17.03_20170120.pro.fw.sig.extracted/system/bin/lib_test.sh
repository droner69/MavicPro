# get elapsed seconds
start=`cat /proc/uptime | busybox awk -F. '{printf $1}'`
elapsed()
{
	local now=`cat /proc/uptime | busybox awk -F. '{printf $1}'`
	local diff=$(($now-$start))
	echo $diff
}

restart()
{
	start=$(date -u +"%s")
}

# run for several times
#   run <times> "expresion"
# example: run 4 "echo aaa && sleep 4"
run()
{
	echo run: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		eval $2
	done
}

# run for several times, return when get error
#   run_error_report <times> "expresion"
# example: run_error_report 4 "echo aaa && sleep 4"
run_error_report()
{
	local r=0
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		eval $2
		r=$?
		if [ $r == 0 ]; then
			echo $2: PASSED
		else
			echo $2: FAILED, errno=$r
			break
		fi
	done

	return $r
}

# run for several times, return when get error
#   run_error_report <times> "expresion"
# example: run_error_report 4 "echo aaa && sleep 4"
run_error_action()
{
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		eval $2
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r
			error_action $r \"$*\"
			return $r
		fi
	done
}

# infinitely run
#   run_inf <expression>
# example 1: run_inf "echo 111 && sleep 5 && echo 222"
# example 2: run_inf test_mem -s 0x800000
run_inf()
{
	echo run_inf: $*
	while true
	do
		eval $*
	done
}

# run ultil timeout defined by $TIMEOUT
#   run_timeout <expression>
# example 1: run_timeout "echo 111 && sleep 5 && echo 222"
# example 2: run_timeout test_mem -s 0x800000
run_timeout()
{
	echo run_timeout: $*
	while [ $(elapsed) -le $timeout ]
	do
		eval $*
	done
}

# infinitely run, if get error, reboot
# same format as run_inf
run_inf_error_reboot()
{
	echo run_inf_error_reboot: $*
	while true
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to reboot.
			reboot
		fi
	done
}

# infinitely run, if get error, stop
# same format as run_inf
run_inf_error_stop()
{
	echo run_inf_error_stop: $*
	while true
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to stop.
			break
		fi
	done
}

# infinitely run, if get error, exit
# same format as run_inf
run_inf_error_exit()
{
	echo run_inf_error_stop: $*
	while true
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to exit.
			exit $r
		fi
	done
}

# infinitely run, if get error, take action
# same format as run_inf
run_inf_error_action()
{
	echo run_inf_error_stop: $*
	while true
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r
			error_action $r \"$*\"
			return $r
		fi
	done
	error_action $? \"$*\"
}

# run until timeout, if get error, reboot
# same format as run_timeout
run_timeout_error_reboot()
{
	echo run_timeout_error_reboot: $*
	while [ $(elapsed) -le $timeout ]
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to reboot.
			reboot
		fi
	done
}

# run until timeout, if get error, stop
# same format as run_timeout
run_timeout_error_stop()
{
	echo run_timeout_error_stop: $*
	while [ $(elapsed) -le $timeout ]
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to stop.
			break
		fi
	done
}

# run until timeout, if get error, exit
# same format as run_timeout
run_timeout_error_exit()
{
	echo run_timeout_error_stop: $*
	while [ $(elapsed) -le $timeout ]
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r, going to exit.
			exit $r
		fi
	done
}

# run until timeout, if get error, take action
# same format as run_timeout
run_timeout_error_action()
{
	echo run_timeout_error_stop: $*
	while [ $(elapsed) -le $timeout ]
	do
		eval $*
		local r=$?
		if [ $r != 0 ]; then
			echo chip $chip_id run \"$*\" get error $r
			error_action $r \"$*\"
			return $r
		fi
	done
	error_action $? \"$*\"
}

# start several instances
#   start <instances> "expression"
# example: start 4 "echo aaa && sleep 4"
start()
{
	echo start: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		eval $2 &
	done
}

# start several times, return when get error
#   start_error_report <instances> "expresion"
# example: start_error_report 4 "echo aaa && sleep 4"
start_error_report()
{
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_error_report 1 \"$2\" &
	done
}

# start several times, execute error_action when get error
#   start_error_action <instances> "expresion"
# example: start_error_action 4 "echo aaa && sleep 4"
start_error_action()
{
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_error_action 1 \"$2\" &
	done
}


# start several applications, which run infinitely
#   start_inf <instances> "expression"
# example: start_inf "echo 111 && sleep 5 && echo 222;"
start_inf()
{
	echo start_inf: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_inf $2 &
	done
}

# start several applications, which run infinitely until get error and reboot.
#   start_inf_error_reboot <instances> "expression"
# example: start_inf_error_reboot 4 "echo 111 && sleep 5 && echo 222;"
start_inf_error_reboot()
{
	echo start_inf_error_reboot: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_inf_error_reboot $2 &
	done
}

# start several applications, which run infinitely until get error and stop
#   start_inf_error_stop <instances> "expression"
# example: start_inf_error_stop 4 "echo 111 && sleep 5 && echo 222"
start_inf_error_stop()
{
	echo start_inf_error_stop: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_inf_error_stop $2 &
	done
}

# start several applications, which run infinitely until get error and exit
#   start_inf_error_exit <instances> "expression"
# example: start_inf_error_exit 4 "echo 111 && sleep 5 && echo 222"
start_inf_error_exit()
{
	echo start_inf_error_exit: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_inf_error_exit $2 &
	done
}

# start several applications, which run infinitely until get error and take action
#   start_inf_error_action <instances> "expression"
# example: start_inf_error_action 4 "echo 111 && sleep 5 && echo 222"
start_inf_error_action()
{
	echo start_inf_error_exit: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_inf_error_action $2 &
	done
}

# start several applications, which run timeoutinitely
#   start_timeout <instances> "expression"
# example: start_timeout "echo 111 && sleep 5 && echo 222;"
start_timeout()
{
	echo start_timeout: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_timeout $2 &
	done
}

# start several applications, which run until timeout or get error then reboot.
#   start_timeout_error_reboot <instances> "expression"
# example: start_timeout_error_reboot 4 "echo 111 && sleep 5 && echo 222;"
start_timeout_error_reboot()
{
	echo start_timeout_error_reboot: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_timeout_error_reboot $2 &
	done
}

# start several applications, which run until timeout or get error then stop
#   start_timeout_error_stop <instances> "expression"
# example: start_timeout_error_stop 4 "echo 111 && sleep 5 && echo 222"
start_timeout_error_stop()
{
	echo start_timeout_error_stop: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_timeout_error_stop $2 &
	done
}

# start several applications, which run until timeout or get error then exit
#   start_timeout_error_exit <instances> "expression"
# example: start_timeout_error_exit 4 "echo 111 && sleep 5 && echo 222"
start_timeout_error_exit()
{
	echo start_timeout_error_exit: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_timeout_error_exit $2 &
	done
}

# start several applications, which run until timeout or get error then take action
#   start_timeout_error_action <instances> "expression"
# example: start_timeout_error_action 4 "echo 111 && sleep 5 && echo 222"
start_timeout_error_action()
{
	echo start_timeout_error_action: $*
	local n=0
	while [ $n -lt $1 ]; do
		let n+=1
		run_timeout_error_action $2 &
	done
}
