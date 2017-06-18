#!/bin/sh

killall -9 cherokee-worker
#cherokee-worker -a -C /etc/cherokee.conf -j -d
. /tmp/start_webserver.sh
