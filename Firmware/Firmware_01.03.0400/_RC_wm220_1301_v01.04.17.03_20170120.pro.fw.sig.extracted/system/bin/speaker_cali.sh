#$1:
#1: IQC, always mode, not write register
#2: speaker + PA calibrate, once mode, write register
if [ $# == 1 ] && [ $1 == 2 ];then
	cali_mode=once
else
	cali_mode=always
fi
echo $cali_mode

####Do the calibration test.
##start music play to offer i2s signal(BCLK and WS clock).
tinyplay /system/bin/silent_amt_cali.wav -p 8192 -n 4& 1>/dev/null
sleep 3
if [ $cali_mode == "once" ];then
	##open tfa98xx
	climax_hostSW --start -l /system/etc/firmware/dji_mono.cnt
	##reset the mtp memory.
	climax_hostSW --resetMtpEx -l /system/etc/firmware/dji_mono.cnt
	##comfirm the reset is success or not.
	climax_hostSW -r0x80
	climax_hostSW --stop -l /system/etc/firmware/dji_mono.cnt
fi
#start calibrate the speaker.
climax_hostSW --calibrate=$cali_mode -l /system/etc/firmware/dji_mono.cnt
##comfirm the calibration is ok or not.
climax_hostSW -r0x80
##show the result of the calibration to check.
climax_hostSW --calshow -l /system/etc/firmware/dji_mono.cnt > /tmp/speaker_cali.log
cat /tmp/speaker_cali.log
##record the status of the tfa98xx ic.
#climax_hostSW --record=543 -l /system/etc/firmware/dji_mono.cnt
kill -9 $(busybox pidof tinyplay)

impedance=`cat /tmp/speaker_cali.log | grep 'impedance' | busybox awk '{ print $4; }'`
tmp1=$(busybox awk 'BEGIN{print '$impedance'-6 }')
tmp2=$(busybox awk 'BEGIN{print 7-'$impedance' }')
echo $tmp1 $tmp2 | busybox awk '{if(($1<0)||($2<0)) {exit 1} else {exit 0}}'
