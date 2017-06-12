mount -o remount,rw /amt
sleep 1

# Country Code file path
COUNTRY_CODE_FILE=/amt/country.txt
# Country Code
COUNTRY_CODE=F2
# Return value
RETVAL=0

# Parameters validation
if [ -z "$1" ]
then
    echo "Usage"
    echo "set_country_code.sh <Country Code>"
    echo "example: set_country_code.sh F2"
    mount -o remount,ro /amt
    exit 1
fi

# Ops checking
if [ -f "$COUNTRY_CODE_FILE" ]
then
   echo "Update $COUNTRY_CODE_FILE"
   rm $COUNTRY_CODE_FILE
fi

# Save country code
echo "save country code"
echo country_code=$1 > $COUNTRY_CODE_FILE
# Check country code
COUNTRY_CODE=`cat $COUNTRY_CODE_FILE | busybox awk -F '=' '{print $2}'`
if [ "$1" != "$COUNTRY_CODE" ]
then
    RETVAL=-1
else
    echo "check country code success"
fi

sync
mount -o remount,ro /amt
exit $RETVAL
