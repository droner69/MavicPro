#!/bin/sh

if [ "$1" != "" ]; then
	CONFFILE=$1
else
	CONFFILE=/usr/local/share/script/ProcList.conf
fi

CURR_PROCLIST=

Find_CurrProc()
{
    CURR_PROCLIST=`ps -eA -o args | grep -v "\["`
}

IsProcExist()
{
    RESULT=`echo ${CURR_PROCLIST} | grep $1`
    if [ -z "${RESULT}" ]; then
        return 0
    else
        return 1
    fi
}

CheckAndRestartProc()
{
    Find_CurrProc
    while read PROC_NAME PROC_PARA
    do
        IsProcExist ${PROC_NAME}
        if [ $? -eq 0 ]; then
            echo "Proc ${PROC_NAME} not exist, restart it(${PROC_NAME} ${PROC_PARA})"
            ${PROC_NAME} ${PROC_PARA} &
        fi
    done < ${CONFFILE}
}

sleep 10
while true
do
    CheckAndRestartProc
    sleep 1
done
echo "Guard unexpected end"


