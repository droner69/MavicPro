#!/system/bin/sh

while [ 1 ]; do
    if [ -d "/sys/class/net/lmi42" ]; then
        echo "/dev/lmi42 ready"
    else
        echo "wait lmi42 to ready"
        sleep 0.1
        continue
    fi
    ip link set lmi42 up
    if [ $? -eq 0 ]; then
        echo "up lmi42 success"
        break
    fi
    echo "wait lmi42 up success"
    sleep 0.1
done

if [ is"$1" = is"uav" ]; then
    ip addr add 192.168.41.1/24 dev lmi42
    ip route add default dev lmi42
    echo "config $1 sdr network done"
fi

if [ is"$1" = is"gnd" ]; then
    ip addr add 192.168.41.2/24 dev lmi42
    ip route add default dev lmi42
    echo "config $1 sdr network done"
fi

if [ is"$1" = is"glass" ]; then
    ip addr add 192.168.41.3/24 dev lmi42
    ip route add default dev lmi42
    echo "config $1 sdr network done"
fi
iperf -s &
