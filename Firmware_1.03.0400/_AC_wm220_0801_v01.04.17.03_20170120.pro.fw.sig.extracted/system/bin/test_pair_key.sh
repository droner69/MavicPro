base=`cat /proc/interrupts | grep GPIO162 | busybox awk '{print $2}'`
now=$base

while [ $now -eq $base ];do
	now=`cat /proc/interrupts | grep GPIO162 | busybox awk '{print $2}'`
done

echo "pair key test pass."

exit 0
