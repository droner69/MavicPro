mount -o remount,rw /amt
sleep 1

mkdir -p /amt/product

if [ ""x == "$1"x ]; then
    echo "Please make sure you have input a real serial number!"
    exit 1
else
    echo "Input serial number: $1"
    echo $1 > /amt/product/sn.txt
    sync
    local stat=`cat /amt/product/sn.txt`
    if [ "$1"x != "$stat"x ]; then
        echo "Failure, should get $1, but get $stat."
        mount -o remount,ro /amt
        exit 1
    else
        mount -o remount,ro /amt
        echo "Success"
    fi
fi

