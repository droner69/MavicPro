#!/system/bin/sh
echo 6 >/sys/class/gpio/export
echo 7 >/sys/class/gpio/export
echo 8 >/sys/class/gpio/export
echo 9 >/sys/class/gpio/export
if [ x"$1" = x"SDR" ] ; then
    echo 0 >/sys/class/gpio/gpio6/value
    echo 1 >/sys/class/gpio/gpio7/value
    echo 0 >/sys/class/gpio/gpio8/value
    echo 1 >/sys/class/gpio/gpio9/value
    sdrs_log_cmd hdvt 17 1
elif [ x"$1" = x"WIFI" ] ; then
    echo 1 >/sys/class/gpio/gpio6/value
    echo 0 >/sys/class/gpio/gpio7/value
    echo 1 >/sys/class/gpio/gpio8/value
    echo 0 >/sys/class/gpio/gpio9/value
    sdrs_log_cmd hdvt 17 0
else
    echo "Please specify SDR or WIFI in argument"
fi
