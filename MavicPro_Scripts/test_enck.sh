cat /proc/cmdline | grep "production" > /dev/null
enck=$?

echo "******************************************"
if [ $enck -eq 0 ]; then
        echo "You've already done encrypt, please go on!"
        echo "******************************************"
        return 0;
else
        echo "Didn't encrypt, need to do encrypt first!"
        echo "******************************************"
        return 1;
fi
