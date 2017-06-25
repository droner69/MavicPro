#!/bin/sh
if [ $# -eq 4 ] && [ "$*" == "03 00 00 00" ]; then
	SendToRTOS photo
elif [ $# -eq 9 ] && [ "$*" == "01 00 00 00 00 00 00 00 00" ]; then
	SendToRTOS record
elif [ $# -eq 3 ] && [ "$*" == "40 00 00" ]; then
	SendToRTOS photo
elif [ $# -eq 3 ] && [ "$*" == "80 00 00" ]; then
	SendToRTOS record
elif [ "${1}" == "photo" ]; then
	SendToRTOS photo
elif [ "${1}" == "record" ]; then
	SendToRTOS record
fi
