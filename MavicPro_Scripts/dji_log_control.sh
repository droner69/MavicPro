#!/system/bin/sh
#
# The hex string format: cmd param1 param2
#
# 000000 Disable log command.
# 000100 Enable log command.
# 010000 Increace log level by 1.
# 020000 Decreace log level by 1.
# 03IDLV Set log level based on module ID. (ID 0x80 for all modules)
# 04IDLV Get log level based on module ID.
# 05IDLV Enable module log level. (ID 0x80 for all modules)
# 06IDLV Disable module log level. (ID 0x80 for all modules)
# 070000 Get total module number.
# 08FM00 Set log format.

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ] ; then
    echo "Usage: ./dji_log_control.sh target_id target_index hex_string"
    exit 1
fi

dji_mb_ctrl -S test -R local -g $1 -t $2 -s 0 -c 0xfa $3
