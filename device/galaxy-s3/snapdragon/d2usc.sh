#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2019, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### d2usc

# This port was possible thanks to the invaluable help of terracota/TeracottaShishi.

# Disk /dev/block/mmcblk0: 61071360 sectors, 29.1 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 61071326
# Total free space is 20397 sectors (10.0 MiB)
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
#   15         3293184        59252735   26.7 GiB    8300  userdata
#   16        59252736        59269119   8.0 MiB     8300  persist
#   17        59269120        60989439   840.0 MiB   8300  cache
#   18        60989440        61009919   10.0 MiB    FFFF  recovery
#   19        61009920        61030399   10.0 MiB    FFFF  fota
#   20        61030400        61042687   6.0 MiB     8300  backup
#   21        61042688        61048831   3.0 MiB     FFFF  fsg
#   22        61048832        61048847   8.0 KiB     FFFF  ssd
#   23        61048848        61059087   5.0 MiB     8300  grow

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:d2usc:*) ;;
        *:d2lte:*) ;;
        *:SCH-R530U:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
