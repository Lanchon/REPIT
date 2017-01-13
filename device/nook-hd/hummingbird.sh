#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### hummingbird

# This port was possible thanks to the invaluable help of BultoPaco.

# Caution: invalid backup GPT header, but valid main header; regenerating
# backup header from main header.
# 
# Warning! Main and backup partition tables differ! Use the 'c' and 'e' options
# on the recovery & transformation menu to examine the two tables.
# 
# Warning! One or more CRCs don't match. You should repair the disk!
# 
# ****************************************************************************
# Caution: Found protective or hybrid MBR and corrupt GPT. Using GPT, but disk
# verification and recovery are STRONGLY recommended.
# ****************************************************************************
# Disk /dev/block/mmcblk0: 31129600 sectors, 14.8 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 4F417C26-4505-4832-9F38-0F1A75E87AFC
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 31129566
# Total free space is 623805 sectors (304.6 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1             256             511   128.0 KiB   8300  xloader
#    2             512            1023   256.0 KiB   8300  bootloader
#    3            1024           31743   15.0 MiB    8300  recovery
#    4           32768           65535   16.0 MiB    8300  boot
#    5           65536          163839   48.0 MiB    8300  rom
#    6          163840          262143   48.0 MiB    8300  bootdata
#    7          262144         1179647   448.0 MiB   8300  factory
#    8         1179648         2555903   672.0 MiB   8300  system
#    9         2555904         3506175   464.0 MiB   8300  cache
#   10         3506176        30507007   12.9 GiB    8300  userdata

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:hummingbird:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}
