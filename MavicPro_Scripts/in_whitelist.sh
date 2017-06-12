#!/system/bin/sh

board=$1
wlist_signed=/data/wm330_debug_whitelist.xml.sig
wlist=/tmp/whitelist.xml

if [ -a $wlist_signed ]; then
	dji_verify -n whitelist -o $wlist $wlist_signed >> /dev/null
	if [ $? == 0 -a -f $wlist ]; then
		line=`grep "\<board sn=\"$board\"" $wlist`
		if [ -n "$line" ]; then
			temp=${line##*level=\"}
			level=${temp%%\"*}
			mkdir -p /tmp/dji
			echo $level > /tmp/dji/secure_debug
			exit 0
		fi
	fi
fi
exit 1
