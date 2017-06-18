#!/system/bin/sh

if [ $# -ne 2 ]; then
	host_id=6
	host_index=0
else
	host_id=$1
	host_index=$2
fi

dji_mb_ctrl -R diag -g $host_id -t $host_index -s 0 -c 1
echo $?
