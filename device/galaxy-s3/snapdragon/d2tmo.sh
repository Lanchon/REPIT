#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2019, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### d2tmo

# This port was possible thanks to the invaluable help of mw-merickso.

# Disk /dev/block/mmcblk0: 30777344 sectors, 14.7 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30765071
# Total free space is 8158 sectors (4.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192          131071   60.0 MiB    0700  modem
#    2          131072          131327   128.0 KiB   FFFF  sbl1
#    3          131328          131839   256.0 KiB   FFFF  sbl2
#    4          131840          132863   512.0 KiB   FFFF  sbl3
#    5          132864          136959   2.0 MiB     FFFF  aboot
#    6          136960          137983   512.0 KiB   FFFF  rpm
#    7          137984          158463   10.0 MiB    FFFF  boot
#    8          158464          159487   512.0 KiB   FFFF  tz
#    9          159488          160511   512.0 KiB   FFFF  pad
#   10          160512          180991   10.0 MiB    8300  param
#   11          180992          208895   13.6 MiB    8300  efs
#   12          208896          215039   3.0 MiB     FFFF  modemst1
#   13          215040          221183   3.0 MiB     FFFF  modemst2
#   14          221184         3293183   1.5 GiB     8300  system
#   15         3293184        28958719   12.2 GiB    8300  userdata
#   16        28958720        28975103   8.0 MiB     8300  persist
#   17        28975104        30695423   840.0 MiB   8300  cache
#   18        30695424        30715903   10.0 MiB    FFFF  recovery
#   19        30715904        30736383   10.0 MiB    FFFF  fota
#   20        30736384        30748671   6.0 MiB     8300  backup
#   21        30748672        30754815   3.0 MiB     FFFF  fsg
#   22        30754816        30754831   8.0 KiB     FFFF  ssd
#   23        30754832        30765071   5.0 MiB     8300  grow

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:d2tmo:*) ;;
        *:d2lte:*) ;;
        *:SGH-T999:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
