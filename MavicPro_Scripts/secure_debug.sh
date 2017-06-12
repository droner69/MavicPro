# call in bellow parameters to check debug
#    username debuglevel password
# say:
#    thomas.edison NonSecurePrivilege deadbeefdeadbeefdeadbeefdeadbeef

user=$1
level=$2
password=$3

enable_secure_debug()
{
	adb_en.sh $1
}

# check whether it is engineering mode
cat /proc/cmdline | grep "production" >> /dev/null
# non production chip, already enabled, just return
if [ $? != 0 ]; then
	exit 0
fi

# if secure debug is already enabled, then just return
if [ -f /tmp/dji/secure_debug ]; then
	exit 0
fi

# get DAAK (Debug Application Authentication Key)
cmdline=`cat /proc/cmdline`
temp=${cmdline##*board_sn=}
board=${temp%% *}
temp=${cmdline##*daak=}
daak=${temp%% *}

if [ "$user" != "" -a "$level" != "" -a "$password" != "" ]; then
	key=`dji_derivekey -s $user:$level -P $daak -x`
	if [ $? == 0 -a "$key" == "$password" ]; then
		enable_secure_debug $level
		exit 0
	fi
fi

# exit with failure
exit 1
