# take pic
#rm /sdcard/DCIM/100MEDIA/*.JPG
#sync
#name="CAP1"
#dji_mb_ctrl -g 1 -t 0 -s 2 -c 0x1 -a 0x40 -1 0x01
#if [ "$?" -ne "0" ]; then
#	echo "TEST $name FAILED!"
#	exit 1
#else
#	echo "TEST $name PASSED!"
#	sync
#	exit 0
#fi
setprop dji.camera_service 0

test_cam_hal -r 1280 720 -fps 30 1 -c 10
