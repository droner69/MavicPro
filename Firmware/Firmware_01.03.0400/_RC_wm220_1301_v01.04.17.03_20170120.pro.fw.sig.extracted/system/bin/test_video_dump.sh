#!/system/bin/sh
if [ x"$1" = x"on" ] ; then
    dji_mb_ctrl -S test -R local -g 14 -t 0 -s 0 -c 0xfb -1 1
elif [ x"$1" = x"off" ] ; then
    dji_mb_ctrl -S test -R local -g 14 -t 0 -s 0 -c 0xfb -1 0
else
    echo "Usage: test_dump_video.sh on|off"
fi
