#!/bin/sh

echo "AMBA TCP Stack Parameters"
ifconfig wlan0 txqueuelen  10000
#echo 10777216 > /proc/sys/net/core/rmem_max
echo 16777216 > /proc/sys/net/core/rmem_max
echo 16777216 > /proc/sys/net/core/wmem_max
#echo '4096 87380 10777216' > /proc/sys/net/ipv4/tcp_rmem
echo '4096 87380 16777216' > /proc/sys/net/ipv4/tcp_rmem
echo '4096 87380 16777216' > /proc/sys/net/ipv4/tcp_wmem
echo 8000 > /proc/sys/net/core/netdev_max_backlog
echo 0 > /proc/sys/net/ipv4/tcp_timestamps

#do this setting will cause timeout every 1 min
#echo 0 > /proc/sys/net/ipv4/tcp_keepalive_probes
echo 0 > /proc/sys/net/ipv4/tcp_sack
