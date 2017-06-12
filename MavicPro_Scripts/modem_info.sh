#!/system/bin/sh

channel=$1
option=$2
env_detect()
{
    if [ $DEVICE_TYPE = "GND" ]; then
        board_type="gnd"
        remote_ip="192.168.41.1"
        local_ip="192.168.41.2"
        lmi6_host_pid=`ps dji_hdvt_gnd | grep dji_hdvt_gnd | busybox awk '{print $2}'`
        lmi6_host_pidname="dji_hdvt_gnd"
        echo "device type is GND"
    elif [ $DEVICE_TYPE = "UAV" ]; then
        board_type="uav"
        remote_ip="192.168.41.2"
        local_ip="192.168.41.1"
        lmi6_host_pid=`ps dji_hdvt_uav | grep dji_hdvt_uav | busybox awk '{print $2}'`
        lmi6_host_pidname="dji_hdvt_uav"
        echo "device type is UAV"
    elif [ $DEVICE_TYPE = "GLASS" ]; then
        board_type="glass"
        remote_ip="192.168.41.1"
        local_ip="192.168.41.2"
        lmi6_host_pid=`ps dji_hdvt_gnd | grep dji_hdvt_gnd | busybox awk '{print $2}'`
        lmi6_host_pidname="dji_hdvt_gnd"
        echo "device type is GLASS"
    else
        echo "do not support device type $DEVICE_TYPE"
        exit 1
    fi
}

function modem_reverse()
{
    ip link set lmi42 down
    sdrs_log_cmd hdvt 19
    sleep 0.3
    local res=-1
    while [ i -lt 20 ]; do
        bootready=`busybox devmem 0xe007ff17 8`
        if [ $bootready = "0x55" ]; then
            res=0
            ip link set lmi42 up
            break
        else
            i=$((i+1))
            sleep 0.3
        fi
    done
    if [ $res -eq -1 ]; then
        echo "modem reverse failed"
        return 1
    else
        echo "modem reverse ok"
        return 0
    fi
    return 1
}

function modem_reboot()
{
    ip link set lmi42 down
    sdrs_log_cmd hdvt 22
    sleep 0.3
    i=0
    local res=-1
    while [ i -lt 20 ]; do
        bootready=`busybox devmem 0xe007ff17 8`
        if [ $bootready = "0x55" ]; then
            res=0
            ip link set lmi42 up
            break
        else
            i=$((i+1))
            sleep 0.3
        fi
    done
    if [ $res -eq -1 ]; then
        echo "modem reboot failed"
        return 1
    else
        echo "modem reboot ok"
        return 0
    fi
    return 1
}

function judge_pair_result()
{
    local pair_type=$1
    for i in $(busybox seq 1 20); do
        sleep 0.05
        cpstate=`busybox devmem 0xe007ff1d 8`
        if [ $cpstate == "0x01" ]; then
            echo "enter into pairing state $cpstate check time $i"
            break
        fi
    done
    if [ $cpstate = "0x01" ]; then
        for i in $(busybox seq 1 120); do
            cpstate=`busybox devmem 0xe007ff1d 8`
            if [ $cpstate == "0x02" ]; then
                echo "$i connected"
                return 0
            elif [ "$pair_type" = "sub" ] && [ $cpstate != "0x01" ]; then
                echo "$i sub gnd connected"
                return 0
            else
               echo "$i not connected"
               sleep 0.5
            fi
        done
    else
        echo "not enter into pairing state, please try again"
        return 1
    fi
    return 1
}
if [ -z $channel ]; then
    channel="modem_info"
fi

if [ is$channel = is"-h" ]; then
    echo "Usage: modem_info.sh lmi_name"
    echo "       modem_info.sh ver     (show modem version)"
    echo "       modem_info.sh VER     (show modem new version format)"
    echo "       modem_info.sh pair    (goto modem pairing state)"
    echo "       modem_info.sh state   (report modem state)"
    echo "       modem_info.sh auto    (enter pairing and report connect state at most 30 times)"
    echo "       modem_info.sh ma      (get ma buffer info)"
    echo "       modem_info.sh cps     (get cp state from cp directly)"
    echo "       modem_info.sh img     (show modem img info)"
    echo "       modem_info.sh set     (show modem set value)"
    echo "       modem_info.sh get     (show modem read value)"
    echo "       modem_info.sh boot    (show modem boot status)"
    echo "       modem_info.sh reboot  (reset modem as normal mode)"
    echo "       modem_info.sh reverse (reset modem as reverse mode)"
    echo "       modem_info.sh pairid  (show pairing self id and remote id)"
    exit 1
fi

if [ is$channel = is"lmi42" ]; then
    cat /sys/devices/platform/comip-modem/net/lmi42/bridge_net_info
elif [[ is$channel = is"lmi0" ||
        is$channel = is"lmi1" ||
        is$channel = is"lmi4" ||
        is$channel = is"lmi5" ||
        is$channel = is"lmi6" ||
        is$channel = is"lmi7" ||
        is$channel = is"lmi10" ||
        is$channel = is"TPC0" ||
        is$channel = is"TPC1" ||
        is$channel = is"socbridge" ]]; then
    cat /sys/devices/platform/comip-modem/misc/$channel/bridge_info
elif [ is$channel = is"pair" ]; then
    mount -o remount,rw /amt
    busybox devmem 0xe007ff1c 8 0x80
    mount -o remount,ro /amt
elif [ is$channel = is"bridge" ]; then
    cat /sys/devices/platform/comip-modem/bridge_info
elif [ is$channel = is"img" ]; then
    cat /sys/devices/platform/comip-modem/img_info
elif [ is$channel = is"set" ]; then
    cat /sys/devices/platform/comip-modem/set_info
elif [ is$channel = is"get" ]; then
    cat /sys/devices/platform/comip-modem/get_info
elif [ is$channel = is"ver" ]; then
    modemarm_ver=$((`busybox devmem 0xe007ff3c 32`))
    modemdsp_ver=$((`busybox devmem 0xe007ff2c 32`))
    debug_flag=`busybox devmem 0xefff0040 32`
    echo "modemarm version: $modemarm_ver"
    echo "modemdsp version: $modemdsp_ver"
    if [ $debug_flag = 0x00000055 ]; then
        echo "modemarm is debug version"
    else
        echo "modemarm is non-debug version"
    fi
elif [ is$channel = is"VER" ]; then
    modemarm_ver=$((`busybox devmem 0xe007ff3c 16`))
    modemarm_patchver=$((`busybox devmem 0xe007ff3e 8`))
    modemarm_typever=$((`busybox devmem 0xe007ff3f 8`))
    modemdsp_ver=$((`busybox devmem 0xe007ff2c 16`))
    modemdsp_patchver=$((`busybox devmem 0xe007ff2e 8`))
    modemdsp_typever=$((`busybox devmem 0xe007ff2f 8`))
    debug_flag=`busybox devmem 0xefff0040 32`
    busybox printf "modemarm version %04d.%d.%02d\n" $modemarm_ver $modemarm_typever $modemarm_patchver
    busybox printf "modemdsp version %04d.%d.%02d\n" $modemdsp_ver $modemdsp_typever $modemdsp_patchver
    if [ $debug_flag = 0x00000055 ]; then
        echo "modemarm is debug version"
    else
        echo "modemarm is non-debug version"
    fi
elif [ is$channel = is"boot" ]; then
    bootstate0=`busybox devmem 0xe007ff20 32`
    bootstate1=`busybox devmem 0xe007ff24 32`
    bootready=`busybox devmem 0xe007ff17 8`
    if [ $bootstate0  = "0xBBEE3388" ] && [ $bootstate1 = "0x00003344" ] && [ $bootready = "0x55" ]; then
        echo "normal boot"
    else
        echo "ignormal boot bootstate0: $bootstate0 bootstate1: $bootstate1 ready: $bootready"
    fi
elif [ is$channel = is"state" ]; then
    env_detect
    if [ -z $lmi6_host_pid ]; then
        echo "$lmi6_host_pidname don't run, exit modem_info.sh"
        exit 1
    fi
    state=`busybox devmem 0xe007ff1c 8`
    if [ $state = '0x00' ]; then
        echo "not work state"
    elif [ $state = "0x01" ]; then
        echo "pairing state"
    elif [ $state = "0x02" ]; then
        echo "normal state"
    elif [ $state = "0x03" ]; then
        echo "lost state"
    elif [ $state = "0x04" ]; then
        echo "arma7 err state"
    elif [ $state = "0x05" ]; then
        echo "dsp err state"
    elif [ $state = "0x06" ]; then
        echo "amt mode state"
    else
        echo "unkown state $state"
    fi
elif [ is$channel = is"cps" ]; then
    cpstate=`busybox devmem 0xe007ff1d 8`
    cpstate_seq=`busybox devmem 0xe007ff1e 8`
    cpsmode=`busybox devmem 0xe007ff30 8`
    if [ $cpsmode = '0x00' ]; then
        cpsmode_str="run as illeage mode"
    elif [ $cpsmode = '0x01' ]; then
        cpsmode_str="run as cp uav mode"
    elif [ $cpsmode = '0x02' ]; then
        cpsmode_str="run as cp gnd mode"
    elif [ $cpsmode = '0x03' ]; then
        cpsmode_str="run as cp glass mode"
    fi

    if [ $cpstate = '0x00' ]; then
        echo "not work state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x01" ]; then
        echo "pairing state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x02" ]; then
        echo "normal state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x03" ]; then
        echo "lost state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x04" ]; then
        echo "arma7 err state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x05" ]; then
        echo "dsp err state, $cpsmode_str, seq $cpstate_seq"
    elif [ $cpstate = "0x06" ]; then
        echo "amt mode state, $cpsmode_str, seq $cpstate_seq"
    else
        echo "unkown state $cpstate, $cpsmode_str, seq $cpstate_seq"
    fi
elif [ is$channel = is"auto" ]; then
    mount -o remount,rw /amt
    env_detect
    if [ -z $lmi6_host_pid ]; then
        echo "$lmi6_host_pidname don't run, exit modem_info.sh"
        exit 1
    fi
    lmi_interface=`busybox ifconfig | busybox awk '/lmi42/ {print $1}'`
    if [ -z $lmi_interface ]; then
        echo "do not find lmi42 network interface"
        echo "cp may not boot ok, auto pair exit"
        exit 1
    fi
    if [ $board_type = "uav" ]; then
        sdrs_log_cmd hdvt 18
    elif [ "$option" = "master" ]; then
        sdrs_log_cmd hdvt 18 0
    elif [ "$option" = "slave" ]; then
        sdrs_log_cmd hdvt 18 1
    elif [ "$option" = "sub" ]; then
        modem_reverse
        sleep 1
        sdrs_log_cmd hdvt 18 2
    else
        sdrs_log_cmd hdvt 18
    fi
    judge_pair_result
    result="fail"
    if [ $? -eq 0 ]; then
        result="success"
    else
        result="fail"
    fi
    echo $result >> /data/dji/log/pair_result.log
    if [ $result = "success" ]; then
        exit 0
    else
        echo "not connected, exit"
        modem_info.sh cps
        modem_info.sh boot
        exit 1
    fi
    mount -o remount,ro /amt
elif [ is$channel = is"ma" ]; then
    buf_base=`busybox devmem 0x633a000 32`
    elem_size=`busybox devmem 0x633a004 32`
    buf_num=`busybox devmem 0x633a008 32`
    w_idx=`busybox devmem 0x633a00c 32`
    r_idx=`busybox devmem 0x633a010 32`
    re_init=`busybox devmem 0x633a014 32`
    echo "ma buf_base  $buf_base"
    echo "ma elem_size $elem_size"
    echo "ma buf_num   $buf_num"
    echo "ma w_idx     $w_idx"
    echo "ma r_idx     $r_idx"
    echo "ma re_init   $re_init"
elif [ is$channel = is"mb" ]; then
    buf_base=`busybox devmem 0x633b000 32`
    elem_size=`busybox devmem 0x633b004 32`
    buf_num=`busybox devmem 0x633b008 32`
    w_idx=`busybox devmem 0x633b00c 32`
    r_idx=`busybox devmem 0x633b010 32`
    re_init=`busybox devmem 0x633b014 32`
    echo "ma buf_base  $buf_base"
    echo "ma elem_size $elem_size"
    echo "ma buf_num   $buf_num"
    echo "ma w_idx     $w_idx"
    echo "ma r_idx     $r_idx"
    echo "ma re_init   $re_init"
elif [ is$channel = is"reboot" ]; then
    ip link set lmi42 down
    sdrs_log_cmd hdvt 22
    sleep 0.3
    i=0
    result=-1
    while [ i -lt 20 ]; do
        bootready=`busybox devmem 0xe007ff17 8`
        if [ $bootready = "0x55" ]; then
            result=0
            ip link set lmi42 up
            break
        else
            i=$((i+1))
            sleep 0.3
        fi
    done
    if [ $result -eq -1 ]; then
        echo "reboot failed"
    else
        echo "reboot ok"
    fi

elif [ is$channel = is"pairid" ]; then
    pair_uav_id=`busybox devmem 0x0619d404 32`
    pair_gnd_id=`busybox devmem 0x0619d408 32`
    echo "pair_uav_id: $pair_uav_id"
    echo "pair_gnd_id: $pair_gnd_id"

elif [ is$channel = is"reverse" ]; then
    ip link set lmi42 down
    sdrs_log_cmd hdvt 19
    sleep 0.3
    result=-1
    while [ i -lt 20 ]; do
        bootready=`busybox devmem 0xe007ff17 8`
        if [ $bootready = "0x55" ]; then
            result=0
            ip link set lmi42 up
            break
        else
            i=$((i+1))
            sleep 0.3
        fi
    done
    if [ $result -eq -1 ]; then
        echo "reboot as reverse failed"
    else
        echo "reboot as reverse ok"

    fi
elif [ is$channel = is"amtmode" ]; then
    env_detect
    if [ $board_type = "uav" ]; then
        process_name="dji_hdvt_uav"
        process_id=`busybox pgrep -f $process_name`
        if [ -n $process_id ]; then
            kill $process_id
        fi
        modem_info.sh reverse
    fi
else
    cat /sys/devices/platform/comip-modem/modem_info
fi
