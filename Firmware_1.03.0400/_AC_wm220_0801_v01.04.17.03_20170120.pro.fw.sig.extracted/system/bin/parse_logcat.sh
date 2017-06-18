#!/system/bin/sh

LOGSERVICES=$1
LOGMODULES=$2
LOGLEVELS="F E"
LOGPATH=/tmp/logcat

echo "Usage: [service list] [module_id list]"

get_module_name_by_id()
{
    if   [ "$1" = "40" ]; then
        MODULE_NAME=osal
    elif [ "$1" = "41" ]; then
        MODULE_NAME=mb
    elif [ "$1" = "42" ]; then
        MODULE_NAME=tm
    elif [ "$1" = "43" ]; then
        MODULE_NAME=event
    elif [ "$1" = "44" ]; then
        MODULE_NAME=sketch
    elif [ "$1" = "45" ]; then
        MODULE_NAME=hal
    elif [ "$1" = "46" ]; then
        MODULE_NAME=usbconn
    elif [ "$1" = "50" ]; then
        MODULE_NAME=testapp
    elif [ "$1" = "51" ]; then
        MODULE_NAME=camera
    elif [ "$1" = "52" ]; then
        MODULE_NAME=ffremux
    elif [ "$1" = "53" ]; then
        MODULE_NAME=wl
    elif [ "$1" = "54" ]; then
        MODULE_NAME=fligthctrl
    elif [ "$1" = "55" ]; then
        MODULE_NAME=rcu
    elif [ "$1" = "56" ]; then
        MODULE_NAME=hdvt_uav
    elif [ "$1" = "57" ]; then
        MODULE_NAME=hdvt_gnd
    elif [ "$1" = "58" ]; then
        MODULE_NAME=encoding
    elif [ "$1" = "59" ]; then
        MODULE_NAME=vision
    elif [ "$1" = "5A" ]; then
        MODULE_NAME=system
    elif [ "$1" = "5B" ]; then
        MODULE_NAME=decoding
    elif [ "$1" = "5C" ]; then
        MODULE_NAME=network
    elif [ "$1" = "5D" ]; then
        MODULE_NAME=glasses
    elif [ "$1" = "5E" ]; then
        MODULE_NAME=flight
    elif [ "$1" = "5F" ]; then
        MODULE_NAME=navigation
    elif [ "$1" = "60" ]; then
        MODULE_NAME=downloading
    elif [ "$1" = "61" ]; then
        MODULE_NAME=domain_sock
    elif [ "$1" = "62" ]; then
        MODULE_NAME=upgrade
    else
        MODULE_NAME=unknow
    fi
}


if [ "$LOGSERVICES" = "" ]; then
    LOGSERVICES="dji_sys dji_hdvt_uav dji_encoding dji_camera dji_vision dji_monitor dji_hdvt_uav dji_hdvt_gnd"
fi

if [ "$LOGMODULES" = "" ]; then
    LOGMODULES="00 40 41 42 43 44 45 46 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F 60 61"
fi

echo "Service list: $LOGSERVICES"
echo "Module id list: $LOGMODULES"

mkdir -p $LOGPATH
for service in $LOGSERVICES; do
    pid=`ps | grep $service | busybox awk '{print $2;}'`
    if [ "$pid" = "" ]; then
        echo "Can't find service $service."
        continue
    fi
    for module in $LOGMODULES; do
        get_module_name_by_id $module
        echo "Capture $service module=$MODULE_NAME ($module)"
        logcat -d -v threadtime *:E | grep "DUSS&$module" | grep "  $pid  " > $LOGPATH/${service}_${MODULE_NAME}.log
    done
done

# Remove all 0 size files
cd $LOGPATH
busybox find . -size 0 -exec rm {} +

