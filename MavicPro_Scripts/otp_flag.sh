if [ $1 == "get" ];then
	opt_finish_flag=`env otp_done`
    echo "otp_flag.sh get value $opt_finish_flag!"
	exit $opt_finish_flag
elif [ $1 == "set" ];then
    echo "otp_flag.sh set 1."
	env otp_done 1
	exit $?
elif [ $1 == "clr" ];then
    echo "otp_flag.sh clr."
	env -d otp_done
	exit $?
else
	exit -1
fi
