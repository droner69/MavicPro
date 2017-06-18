#!/bin/sh

## After you customize your cipher,
## please try to encrypt and decrypt as this example
# $ echo -n 12345678901234567890123456789012 > /tmp/challenge
# $ ./cmdctr.cipher.sh encrypt 1234 /tmp/challenge
# $ ./cmdctr.cipher.sh decrypt 1234 /tmp/response
# 12345678901234567890123456789012

if [ $# -lt 3 ] || [ ! -e ${3} ] ; then
	echo "Usage: ${0} decrypt <passphrase> <input file to be decrypted>"
	echo "Example: ${0} decrypt 1234 /tmp/response"
	echo "(Prepare input file in /tmp/response before use)"
	#echo "${0} encrypt 1234 /tmp/challenge"
fi

if [ "${1}" == "encrypt" ]; then
	#DEBUG only: camera should never encrypt and generate response
	openssl bf-cbc -e -pass pass:${2} -salt -in ${3} -out /tmp/response
	exit 0
fi

if [ "${1}" == "decrypt" ]; then
	openssl bf-cbc -d -pass pass:${2} -salt -in ${3}
fi
