/bin/mount -t proc none /proc

for x in $(cat /proc/cmdline); do
        case $x in
	root=*)
                ROOT="${x#root=}"
		;;
	nfsroot=*)
                NFSROOT="${x#nfsroot=}"
		;;
	ip=*)
                IP="${x#ip=}"
                ;;
	esac
done

if [ "x${ROOT}" = "x/dev/nfs" ]; then
	MNT_DIR=/mnt/nfsroot
	mkdir /mnt/nfsroot
	/bin/mount -t nfs -o nolock,tcp ${NFSROOT} ${MNT_DIR}
	mount --bind /dev ${MNT_DIR}/dev
	echo "<<<   Switching to NFSROOT -- ${NFSROOT}  >>>"
	exec switch_root ${MNT_DIR} /linuxrc
fi
