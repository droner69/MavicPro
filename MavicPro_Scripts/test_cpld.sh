cpld_dir=/data/dji/amt/factory_out/cpld
cat $cpld_dir/log.txt
if [ -f $cpld_dir/result ];then
	exit `cat $cpld_dir/result`
else
	echo no program cpld result!!
	exit 1
fi
