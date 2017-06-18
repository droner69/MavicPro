#!/bin/sh
if [ -e /sys/module/ath6kl_sdio/parameters/low_cpu_power_tx_bundle_max ]; then
	echo 6 > /sys/module/ath6kl_sdio/parameters/low_cpu_power_tx_bundle_max
elif [ -e /sys/module/bcmdhd/parameters/g_txglom_max_agg_num ]; then
	echo 16 > /sys/module/bcmdhd/parameters/g_txglom_max_agg_num
fi
