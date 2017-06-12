##     check connection.log --> get ma2100 and usb status 
##                          --> if ma2100 and usb status okay, check syslog
##                          --> check ma2100 reset
##                          --> return syslog status`
##
##     return value: 0: ma2100 connection ok and syslog okay
##                   1: ma2100 connection ok, syslog contains error
##                   2: ma2100 load image fail
##                   3: usb init fail
##                   4: current sys log not exist   
##                   5: connection.log not exist    
##                   6: syslog size overflow
##                   7: ma2100 reset
##                   10: default value
##
##
##    update  

result=100
newLineNo=0
#pattern='error|warning'
pattern='error'
ma2100_error="ERROR:loading MA2100 image failed"
ma2100_reset="ERROR:MA2100 reset"
usb_error="ERROR:init_usb failure"
timeLimit=10
maxSize=8192  #size:KB #20971520 #5242880
fname=test.log
fileName='sys.log'
agingDir='/aging'
retLog='/blackbox/vision/aging/sys.log'
SyslogCount=0
OldSyslogCount=0
connectName='connection.log'
fPath='/blackbox/vision'
emmc_index='/blackbox/vision/emmc_index'
ret=10

function ck1(){
busybox awk -F , '
BEGIN{count=0}
function f3(){
    if ($3 == "ERROR" || $3 == "FATAL"){
        count++
    }
}
{
f3()
}
END{print count}
' $1
}
    
function searchContext()
{
    errCount=$(ck1 $1) 
    echo "error Count == $errCount"
    if [ $errCount == 0 ]; then
        return 1;
    else
        return 0;
    fi
}

function checkConnection()
{
    if [ ! -f "$1" ]; then
        ret=5
        return 1
    fi

    grep -iE "$ma2100_error" $1
    if [ $? -eq 0 ]; then
        ret=2
        #echo "ma2100 load image fail"
        cat $1
        return 1
    fi

    grep -iE "$usb_error" $1
    if [ $? -eq 0 ]; then 
        ret=3;
        #echo "usb init fail"
        return 1
    fi

    grep -iE "$ma2100_reset" $1
    if [ $? -eq 0 ]; then 
        ret=7;
        #echo "ma2100 reset,error"
        cat $1
        return 1
    fi
    return 0
} 

function checkParams()
{
    [ -f "$1" ] && fname=$1 || ret=4
    [ -n "$2" ] && timeLimit=$2
}

function retProcess()
{
   #echo "result == [$ret]"
   case $ret in
      0)
     echo "no error or warning"
     exit 0;
     ;;
      1) echo "syslog contains error"
     cat $retLog
         exit 1
     ;;
      2) echo "ma2100 load image fail"
     exit 1 
     ;;
      3) echo "usb init fail"
     exit 1 
     ;;
      4) echo "$fname file not exist"
     exit 1
         ;;
      5) echo "connection.log file not exist"
     exit 1 
     ;;
      6) echo "syslog overflow"
     exit 1 
     ;;
      7) echo "ma2100 reset"
     exit 1 
         ;;
   esac
} 

function dumpError()
{
    #echo "dumpError"
    if [ ! -f "$retLog" ];then
        touch $retLog
    fi
    cat $1 >> $retLog
}

function checkSize()
{
    size=$(busybox du -c $fname* | busybox awk 'END{print $1}')
    echo "syslog size==$size, maxSize == $maxSize"
    if [ $size -ge $maxSize ];then
        ret=6
    else
        echo "check syslog Size ok"
    fi
}

function main()
{
    date_start=$(date +%s)
    timeDiff=0
    while [ $timeDiff -lt $timeLimit ]
    do
    i=$(($SyslogCount-1))
    echo '' > $retLog # override last error sys.log, always show the latest error sys.log
    while [ i -ge 0 ]
    do
        if [ $i == 0 ];then
            #echo "AAA"
            searchContext $fname
        else
            #echo "BBB"
            searchContext $fname.$i
        fi

        if [ $? == 0 ];then
            ret=1
            echo "syslog[$i] error"
            if [ $i == 0 ];then
                dumpError $fname
            else
                dumpError $fname.$i
            fi
        fi

        i=$(($i-1))
    done
    retProcess # if found error, exit
    SyslogCount=$(busybox find $fname* | busybox awk 'END {print NR}')
    date_end=$(date +%s)
    timeDiff=$((date_end-date_start))
    sleep 1
    done ;
    echo "program cost: $timeDiff seconds"
    [ $ret = 10 ] && ret=0
}

#get latest log directory
cmd=$(cat $emmc_index)
echo "cmd == $cmd"
connectionLog=$fPath/$cmd/$connectName
echo "connectionLog $connectionLog"
checkConnection $connectionLog
retProcess
fname=$fPath/$cmd/$fileName

# create aging sys.log which record error log
if [ ! -d $fpath$agingDir ];then
    mkdir -p $fPath$agingDir
fi
touch '$retLog'

SyslogCount=$(busybox find $fname* | busybox awk 'END {print NR}')
OldSyslogCount=$SyslogCount
echo "SyslogCount == $SyslogCount"
[ -n "$1" ] && timeLimit=$1

if [ $SyslogCount == 0 ];then
    ret=4
    retProcess
elif [ $SyslogCount == 4 ];then
    checkSize
    retProcess
fi

main
retProcess
