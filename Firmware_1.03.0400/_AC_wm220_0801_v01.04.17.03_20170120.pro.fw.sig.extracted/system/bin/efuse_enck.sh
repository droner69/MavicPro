#!/system/xbin/busybox sh
state=`efuse -r -s 112 -l 4`
echo "Value of data28 is 0x$state."

echo "******************************************"
SE=`printf "%x\n" $(( 0x1 & 0x$state ))`
echo "SE is $SE."

if [ $SE -eq 0 ]; then
        echo "Secure boot has not be enabled!"
else
        echo "Secure boot has alreay been enabled!"
fi

echo "******************************************"
ST=`printf "%x\n" $(( 0x2 & 0x$state ))`
echo "ST is $ST."

if [ $ST -eq 0 ]; then
        echo "JTAG enable!"
else
        echo "JTAG disable!"
fi

echo "******************************************"
SET=`printf "%x\n" $(( 0x8 & 0x$state ))`
echo "SET is $SET."

if [ $SET -eq 0 ]; then
        echo "The OTP could be program!"
else
        echo "The OTP could not be program anymore!"
fi

# Actually we could check if the value of otp is conflict with the otp
# value generated on secure data server. Should be as below:
# (!otp_server_data) & otp_board_data == 0
echo "******************************************"
dd if=/dev/zero of=/tmp/otp_ref.bin bs=1 count=128
efuse -r -s 20 -l 92 -f /tmp/otp_dump.bin
busybox diff /tmp/otp_ref.bin /tmp/otp_dump.bin
data_other=$?

if [ $data_other -eq 0 ]; then
        echo "The OTP data is empty!"
else
        echo "The OTP data already write done!"
fi

echo "******************************************"
echo "******************************************"
echo "******************************************"
if [ $SE -eq 0 -a $data_other -eq 0 ]; then
        echo "Didn't encrypt, need to do encrypt first!"
        return 1;
else
        echo "You've already done encrypt, please go on!"
        return 0;
fi
echo "******************************************"
echo "******************************************"
echo "******************************************"
