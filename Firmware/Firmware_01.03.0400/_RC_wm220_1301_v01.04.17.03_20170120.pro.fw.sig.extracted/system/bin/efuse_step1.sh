echo "Will start to do efuse_step1.sh $1 ..."

efusebuf=/dev/block/platform/comip-mmc.1/by-name/panic

dji_chkotp $1
result=$?
if [ 0 -eq $result ]; then
	echo "efuse_step1.sh $1 crc success."
	local n=0
	while [ $n -lt 3 ]; do
		let n+=1
		dd if=$1 of=$efusebuf bs=1 count=128
		result=$?
		if [ 0 -eq $result ]; then
			dji_chkotp $efusebuf
			result=$?
			if [ 0 -eq $result ]; then
				env encrypt.stage efuse_data
				echo "efuse_step1.sh $1 success."
				break;
			else
				echo "check otp in emcp failure."
			fi
		else
			echo "efuse_step1.sh $1 failure."
		fi
	done
else
	echo "efuse_step1.sh $1 crc failure."
fi

return $result
