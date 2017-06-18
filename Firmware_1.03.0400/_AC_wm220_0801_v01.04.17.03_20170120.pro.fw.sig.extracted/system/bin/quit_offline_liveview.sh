#wm220 offine liveview quality test mode quit

echo "entry cap mode"
dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c 10 -q 12 -a 40 -1 0

echo "sleep 20 to wait A9 ready"
sleep 20

echo "quit offline liveview mode"
dji_mb_ctrl -S test -R diag -g 1 -t 0 -s 2 -c FF -q 22 -a 40 -1 0

exit 1
