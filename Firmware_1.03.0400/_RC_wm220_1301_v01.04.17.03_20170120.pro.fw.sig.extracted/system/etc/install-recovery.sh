#!/system/bin/sh

if ! applypatch -c EMMC:/dev/block/platform/comip-mmc.1/by-name/ramdisk_recovery::; then
  log -t recovery "Installing new recovery image"
  dd if=/system/etc/ramdisk_recovery.img of=/dev/block/platform/comip-mmc.1/by-name/ramdisk_recovery
else
  log -t recovery "recovery image already installed"
fi

if ! applypatch -c EMMC:/dev/block/platform/comip-mmc.1/by-name/kernel_recovery::; then
  log -t recovery "Installing new kernel recovery image"
  dd if=/system/etc/kernel_recovery of=/dev/block/platform/comip-mmc.1/by-name/kernel_recovery
else
  log -t recovery "kernel recovery image already installed"
fi
