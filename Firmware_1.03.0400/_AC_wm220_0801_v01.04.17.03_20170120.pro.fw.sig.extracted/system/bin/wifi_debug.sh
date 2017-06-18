#! /system/bin/sh

### BEGIN INFO
# Used to capture wifi debug
# ath6kl_usb device.
# Provides:		Gannicus Guo
### END INFO

#echo "Start to capture Wi-Fi Debug log"
# Definitions
# usb mount point
USB_STORAGE_DIR=/data/usbstorage
# wifi debug on/off
DEBUG_ON=$USB_STORAGE_DIR/wifi.debug
# check intervals
CHECK_INTERVAL=3
WLAN_INTF_CHECK=2
# tcpdump file definition
TCPDUMP_LOG_PRE=$USB_STORAGE_DIR/tcp_udt
TCPDUMP_LOG_SUF=.pcap
TCPDUMP_LOG_NUM=0
TCPDUMP_FILE=${TCPDUMP_LOG_PRE}${TCPDUMP_LOG_NUM}${TCPDUMP_LOG_SUF}
# dmesg file definition
DMESG_FILE=$USB_STORAGE_DIR/wifi_dmesg.log
# log cat file definition
DJI_NETWORK_PID=0
DJI_NETWORK_LOG=$USB_STORAGE_DIR/dji_network.log
DJI_ENCODING_PID=0
DJI_ENCODING_LOG=$USB_STORAGE_DIR/dji_encoding.log
DJI_HDVT_UAV_PID=0
DJI_HDVT_UAV_LOG=$USB_STORAGE_DIR/dji_hdvt_uav.log
HOSTAPD_PID=0
HOSTAPD_LOG=$USB_STORAGE_DIR/hostapd.log
# log folder definition
LOG_DIR=/data/usbstorage/log
# folder index
FOLDER_NUM=0

# logcat log
check_dji_network()
{
	DJI_NETWORK_PID=`ps | grep dji_network | busybox awk -F ' ' '{print $2}' | busybox sed -n '1,1p'`
	logcat -v threadtime | grep "  "${DJI_NETWORK_PID}" " > $DJI_NETWORK_LOG &
}

check_dji_encoding()
{
	DJI_ENCODING_PID=`ps | grep dji_encoding | busybox awk -F ' ' '{print $2}' | busybox sed -n '1,1p'`
	logcat -v threadtime | grep "  "${DJI_ENCODING_PID}" " > $DJI_ENCODING_LOG &
}

check_dji_hdvt_uav()
{
	DJI_HDVT_UAV_PID=`ps | grep dji_hdvt_uav | busybox awk -F ' ' '{print $2}' | busybox sed -n '1,1p'`
	logcat -v threadtime | grep "  "${DJI_HDVT_UAV_PID}" " > $DJI_HDVT_UAV_LOG &
}

check_hostapd()
{
	HOSTAPD_PID=`ps | grep hostapd | busybox awk -F ' ' '{print $2}' | busybox sed -n '1,1p'`
	logcat -v threadtime -s hostapd > $HOSTAPD_LOG &
}

# dmesg log
check_wifi_dmesg()
{
	dmesg > /tmp/dmesg
	grep -E 'ath6k|hostapd' /tmp/dmesg >> $DMESG_FILE
}

# Check USB device
while [ 1 ]
do
    if [ ! -d $USB_STORAGE_DIR ]
    then
	    #echo "No usb device mounted"
	    sleep $CHECK_INTERVAL
	  else
	    #echo "Usb device mounted"
	    if [ ! -f "$DEBUG_ON" ]
	    then
	        #echo "Wi-Fi debug off, please touch wifi.debug in usb device"
	        sleep $CHECK_INTERVAL
      else
          #echo "Start capture wifi debug log"
          break
      fi
    fi
done

# Check and Move log files
if [ ! -d $LOG_DIR ]
then
    mkdir -p $LOG_DIR
else
    ls $LOG_DIR > /tmp/wifi_folders
	  FOLDER_NUM=`busybox wc -l /tmp/wifi_folders | busybox awk '{ print $1}'`
	  if [ $FOLDER_NUM == 0 ]
	  then
	      let FOLDER_NUM=0
	  else
		    busybox sort -g /tmp/wifi_folders > /tmp/wifi_folders_sort
		    FOLDER_NUM=`busybox tail /tmp/wifi_folders_sort -n 1`
		    let FOLDER_NUM+=1
	  fi
fi

# mov log files to log folder
if [ `busybox ls $USB_STORAGE_DIR | grep -c tcp_udt` -gt 0 ]
then
    # log folder
    LOG_DIR=${LOG_DIR}"/"${FOLDER_NUM}
    mkdir -p $LOG_DIR
    mv $USB_STORAGE_DIR/*.pcap $LOG_DIR
    mv $USB_STORAGE_DIR/*.log $LOG_DIR
fi

check_dji_network
check_dji_encoding
check_dji_hdvt_uav
check_hostapd

# Check wlan0 interface
while [ 1 ]
do
    busybox ifconfig wlan0
    if [ $? != 0 ]
    then
        #echo "Waiting for wlan0 device ready..."
        sleep $WLAN_INTF_CHECK
    else
        #echo "Start tcpdump"
        tcpdump -i wlan0 -s 256 -w $TCPDUMP_FILE 1>/dev/null&
        break
    fi
done

# Check and restart tcpdump
while [ 1 ]
do
    if [ `ps | grep -c tcpdump` -gt 0 ]
    then
        #echo "tcpdump already started"
        sleep $CHECK_INTERVAL
        check_wifi_dmesg
    else
        #echo "Restart tcpdump"
	TCPDUMP_LOG_NUM=`busybox expr $TCPDUMP_LOG_NUM + 1`
	TCPDUMP_FILE=${TCPDUMP_LOG_PRE}${TCPDUMP_LOG_NUM}${TCPDUMP_LOG_SUF}
        tcpdump -i wlan0 -s 256 -w $TCPDUMP_FILE 1>/dev/null &
    fi
done
