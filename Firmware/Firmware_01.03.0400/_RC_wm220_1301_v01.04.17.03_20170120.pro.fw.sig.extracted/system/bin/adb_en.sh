#!/system/bin/sh

level=$1
: ${level:=NonSecurePrivilege}

# mark debug enable
mkdir -p /tmp/dji
echo $level > /tmp/dji/secure_debug

# init adb device serial
if [ -f /data/dji/cfg/adb_serial ]; then
serial=`cat /data/dji/cfg/adb_serial`
busybox printf "$serial" > /sys/class/android_usb/android0/iSerial
fi

setprop service.adb.root 1
setprop service.adb.tcp.port -1
setprop sys.usb.config rndis,mass_storage,bulk,acm,adb
busybox devmem 0xe10093d0 8 0x40	#enable uart
sleep 1
busybox udhcpd

