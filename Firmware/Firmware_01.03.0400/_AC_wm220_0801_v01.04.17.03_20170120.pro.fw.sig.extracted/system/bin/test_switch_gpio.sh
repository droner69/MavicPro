count=0;
gpio_val=0;
temp=0;
echo 199 > /sys/class/gpio/export

gpio_val=`cat /sys/class/gpio/gpio199/value`

#echo "initial gpio_val is $gpio_val!"

while [ count -lt 2 ]; do
	temp=`cat /sys/class/gpio/gpio199/value`
	if [ temp -ne gpio_val ];then
		gpio_val=$temp;
		let count+=1
#		echo "temp = $temp, gpio_val = $gpio_val!"
	fi
done

echo "switch gpio 199 test pass"

exit 0
