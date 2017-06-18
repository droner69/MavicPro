####Speaker leaky test.
check_spks()
{
	cat /tmp/spks.log | grep "SPKS:0" 1>/dev/null
	return $?
}
calc_f0()
{
	for file in `ls /tmp/f0.log`;do busybox sed -n -e '5p' $file > /tmp/f0_tmp;done
	finit=`busybox  awk -F'[ ,]' '{print $7}' /tmp/f0_tmp`
	fres=`busybox  awk -F'[ ,]' '{print $8}' /tmp/f0_tmp`
	fmin=$(echo $finit 0.8 | busybox awk '{ printf "%f\n" ,$1*$2}')
	fmax=$(echo $finit 1.2 | busybox awk '{ printf "%f\n" ,$1*$2}')
	tmp1=$(busybox awk 'BEGIN{print '$fres'-'$fmin' }')
	tmp2=$(busybox awk 'BEGIN{print '$fmax'-'$fres' }')
	echo $tmp1 $tmp2 | busybox awk '{if(($1<0)||($2<0)) {return 1} else {return 0}}'
}

##start music play 5 second at least.
tinyplay /system/bin/pinknoise_amt_leaky.wav -p 8192 -n 4& 1>/dev/null
sleep 5
##open tfa98xx
#climax_hostSW --start -l /system/etc/firmware/dji_mono.cnt

##the test below should run one time every 3s, total 10 times.
##check status register 0x00 SPKS bit 11

local n=0
	while [ $n -lt 10 ];	do
		let n+=1
		#climax_hostSW -r0x00
		climax_hostSW --dump -l /system/etc/firmware/dji_mono.cnt > /tmp/spks.log
		cat /tmp/spks.log
		check_spks
		if [ $? == 1 ];then
			kill -9 $(busybox pidof tinyplay)
			return 1
		fi
		##dump the speaker model to check the f0(fRes and fInit).
		climax_hostSW --dumpmodel=z -l /system/etc/firmware/dji_mono.cnt > /tmp/f0.log
		cat /tmp/f0.log
		calc_f0
		if [ $? == 1 ];then
			kill -9 $(busybox pidof tinyplay)
			return 1
		fi
	done
kill -9 $(busybox pidof tinyplay)
