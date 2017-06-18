#! /system/bin/sh

### BEGIN INFO
# Used to start WIFI fix frequency tx
# ath6kl_usb device.
# Provides: Gannicus Guo
### END INFO
/system/bin/test_wifi_antenna.sh
# txchain (1:on chain 0, 2:on chain 1, 3:on both)
# txpwr <0-30dBm, 0.5 dBm resolution; sine: 0-60, PCDAC vaule>
# txrate <rate index>
# <rate> 0    1   Mb
# <rate> 1    2   Mb
# <rate> 2    5.5 Mb
# <rate> 3    11  Mb
# <rate> 4    6   Mb
# <rate> 5    9   Mb
# <rate> 6    12  Mb
# <rate> 7    18  Mb
# <rate> 8    24  Mb
# <rate> 9    36  Mb
# <rate> 10   48  Mb
# <rate> 11   54  Mb
# <rate> 12   HT20 MCS0 6.5   Mb
# <rate> 13   HT20 MCS1 13    Mb
# <rate> 14   HT20 MCS2 19.5  Mb
# <rate> 15   HT20 MCS3 26    Mb
# <rate> 16   HT20 MCS4 39    Mb
# <rate> 17   HT20 MCS5 52    Mb
# <rate> 18   HT20 MCS6 58.5  Mb
# <rate> 19   HT20 MCS7 65    Mb
# <rate> 20   HT20 MCS8 13    Mb
# <rate> 21   HT20 MCS9 26    Mb
# <rate> 22   HT20 MCS10 39   Mb
# <rate> 23   HT20 MCS11 52   Mb
# <rate> 24   HT20 MCS12 78   Mb
# <rate> 25   HT20 MCS13 104  Mb
# <rate> 26   HT20 MCS14 117  Mb
# <rate> 27   HT20 MCS15 130  Mb
# <rate> 28   HT40 MCS0 13.5    Mb
# <rate> 29   HT40 MCS1 27.0    Mb
# <rate> 30   HT40 MCS2 40.5    Mb
# <rate> 31   HT40 MCS3 54      Mb
# <rate> 32   HT40 MCS4 81      Mb
# <rate> 33   HT40 MCS5 108     Mb
# <rate> 34   HT40 MCS6 121.5   Mb
# <rate> 35   HT40 MCS7 135     Mb
# <rate> 36   HT40 MCS8 27      Mb
# <rate> 37   HT40 MCS9 54      Mb
# <rate> 38   HT40 MCS10 81     Mb
# <rate> 39   HT40 MCS11 108    Mb
# <rate> 40   HT40 MCS12 162    Mb
# <rate> 41   HT40 MCS13 216    Mb
# <rate> 42   HT40 MCS14 243    Mb
# <rate> 43   HT40 MCS15 270    Mb
# <rate> 44   2(S)   Mb
# <rate> 45   5.5(S) Mb
# <rate> 46   11(S)  Mb

# freq
# 2.4G
# channel:   1     2     3     4     5     6     7     8     9     10    11    12    13    14
# frequency: 2412  2417  2422  2427  2432  2437  2442  2447  2452  2457  2462  2467  2472  2484
# 5G
# channel:   36    40    44    48    52    56    60    64
# frequency: 5180  5200  5220  5240  5260  5280  5300  5320
# channel:   100   104   108   112   116   120   124   128   132   136   140
# frequency: 5500  5520  5540  5560  5580  5600  5620  5640  5660  5680  5700
# channel:   149   153   157   161   165
# frequency: 5745  5765  5785  5805  5825

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ]
then
    echo "Usage: wifi_test.sh <txchain> <txfreq> <txrate> <txpower>"
    echo "<txchain> 1:on chain 0, 2:on chain 1, 3:on both"
    echo "<txfreq> 2.4G;5G frequency"
    echo "<txrate> 0-46"
    echo "<txpwr> 0-30dBm, 0.5 dBm resolution; sine: 0-60, PCDAC vaule"
    exit 1
fi

athtestcmd -i wlan0 --tx tx99 --txchain $1 --txfreq $2 --txrate $3 --paprd --txpwr $4
#athtestcmd -i wlan0 --tx tx99 --txchain 3 --txfreq 5500 --txrate 4 --paprd --txpwr 15
exit 0
