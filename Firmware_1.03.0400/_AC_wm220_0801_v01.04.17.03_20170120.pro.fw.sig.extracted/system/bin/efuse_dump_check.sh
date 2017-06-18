dd if=/dev/zero of=/tmp/otp_ref.bin bs=1 count=128
efuse -r -s 20 -l 92 -f /tmp/otp_dump.bin
busybox diff /tmp/otp_ref.bin /tmp/otp_dump.bin
