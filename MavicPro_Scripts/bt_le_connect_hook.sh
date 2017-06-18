#!/bin/sh
sysl=`ps | grep syslogd | grep -v grep`
LOGGER ()
{
	if [ "${sysl}" == "" ]; then
		echo "$@"
	else
		logger "$@"
	fi
}

sleep 0.5
LOGGER "$@"

padding()
{
	for i in `seq ${pad_len}`; do
		echo -n "00 "
	done
}

#for customer to hook their setting
HCI_LE_Set_Advertising_Parameters ()
{
	#HCI Command: LE Set Advertise Disable
	hcitool cmd 0x08 0x000A 00

	#HCI Command: LE Set Advertising Parameters
	#500 ms
	Advertising_Interval_Min="20 03"
	#4 sec
	Advertising_Interval_Max="00 19"
	Advertising_Type_Connectable="00"
	Own_Address_Type_public=00
	Direct_Address_Type_public=00
	Direct_Address="00 00 00 00 00 00"
	Advertising_Channel_Map_all=07
	Advertising_Filter_Policy_nowhite=00
	hcitool cmd 0x08 0x0006 $Advertising_Interval_Min $Advertising_Interval_Max \
	$Advertising_Type_Connectable $Own_Address_Type_public $Direct_Address_Type_public $Direct_Address \
	$Advertising_Channel_Map_all $Advertising_Filter_Policy_nowhite

	#HCI Command: LE Set Advertise Enable
	hcitool cmd 0x08 0x000A 01

	#NOTE: Android need flag 0x1e to skip pairing
	#HCI Command: LE Set Advertising Data
	DEVICE_NAME=`cat /pref/bt.conf |grep DEVICE_NAME|cut -c 13-`
	DEVICE_NAME_LEN=`echo $DEVICE_NAME|wc -c`
	cmd_len="1e"
	flag_len="02"
	flag_type="01"
	flag="1e"
	power_len="02"
	power_type="0a"
	power="04"
	name_len=`printf %02x $DEVICE_NAME_LEN`
	name_type="09"
	name=`echo -n $DEVICE_NAME|hexdump -C|grep 00000000|sed 's/00000000//'|cut -d '|' -f 1`
	pad_len=$((30 - ${DEVICE_NAME_LEN} - 6))
	hcitool cmd 0x08 0x0008 $cmd_len $flag_len $flag_type $flag \
	$power_len $power_type $power \
	$name_len $name_type $name \
	`padding`
}

#fix bluez5 hci_le_set_advertise_enable segmentation fault
if [ "${1}" == "leadv5" ]; then
	HCI_LE_Set_Advertising_Parameters
fi

##GATT connected: reduce power consumption by disable piscan
#if [ "${1}" == "connected" ]; then
#	hciconfig hci0 noscan
#fi
#
##GATT disconnected: restore piscan status, restart advertising
#if [ "${1}" == "leadv" ]; then
#	bt_conf=`cat /pref/bt.conf | grep -Ev "^#"`
#	export `echo "${bt_conf}"|grep -vI $'^\xEF\xBB\xBF'`
#
#	if [ "${PSCAN}" == "yes" ] && [ "${ISCAN}" == "yes" ] && [ $BT_DISCOVERABLE_TIMEOUT -eq 0 ]; then
#		hciconfig hci0 piscan
#	elif [ "${ISCAN}" == "yes" ] && [ $BT_DISCOVERABLE_TIMEOUT -eq 0 ]; then
#		hciconfig hci0 iscan
#	elif [ "${PSCAN}" == "yes" ]; then
#		hciconfig hci0 pscan
#	fi
#fi
