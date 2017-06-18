#!/bin/sh
if [ -e /sys/module/ath6kl_sdio/parameters/low_cpu_power_tx_bundle_max ]; then
	echo 0 > /sys/module/ath6kl_sdio/parameters/low_cpu_power_tx_bundle_max
elif [ -e /sys/module/bcmdhd/parameters/tx_coll_max_time ]; then
	echo 0 > /sys/module/bcmdhd/parameters/tx_coll_max_time
#elif [ -e /sys/module/bcmdhd/parameters/g_txglom_max_agg_num ]; then
#	echo 0 > /sys/module/bcmdhd/parameters/g_txglom_max_agg_num
fi
