#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### i9305

# This port was possible thanks to the invaluable help of nishimura-san.

# Disk /dev/block/mmcblk0: 30777344 sectors, 14.7 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 52444E41-494F-2044-4D4D-43204449534B
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30777310
# Total free space is 16317 sectors (8.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192           16383   4.0 MiB     0700  BOTA0
#    2           16384           24575   4.0 MiB     0700  BOTA1
#    3           24576           65535   20.0 MiB    0700  EFS
#    4           65536           73727   4.0 MiB     0700  m9kefs1
#    5           73728           81919   4.0 MiB     0700  m9kefs2
#    6           81920           90111   4.0 MiB     0700  m9kefs3
#    7           90112          106495   8.0 MiB     0700  PARAM
#    8          106496          122879   8.0 MiB     0700  BOOT
#    9          122880          139263   8.0 MiB     0700  RECOVERY
#   10          139264          319487   88.0 MiB    0700  RADIO
#   11          319488          843775   256.0 MiB   0700  TOMBSTONES
#   12          843776         2940927   1024.0 MiB  0700  CACHE
#   13         2940928         6086655   1.5 GiB     0700  SYSTEM
#   14         6086656         7233535   560.0 MiB   0700  HIDDEN
#   15         7233536         7249919   8.0 MiB     0700  OTA
#   16         7249920        30769151   11.2 GiB    0700  USERDATA

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="tombstones=same-cache=32M+wipe-system=1G-preload=min+wipe-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:m3:*) ;;
        *:m3xx:*) ;;
        *:i9305:*) ;;
        *:GT-I9305:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/platform/dw_mmc/mmc_host/mmc0/mmc0:0001/block/mmcblk0
    sdev=/sys/block/mmcblk0
    spar=$sdev/mmcblk0p

    ddev=/dev/block/mmcblk0
    dpar=/dev/block/mmcblk0p

    sectorSize=512      # in bytes

    # a grep pattern matching the partitions that must be unmounted before REPIT can start:
    #unmountPattern="${dpar}[0-9]\+"
    unmountPattern="/dev/block/mmcblk[^ ]*"

}

device_initPartitions() {

    # the crypto footer size:
    local footerSize=$(( 16384 / sectorSize ))

    # the set of partitions that can be modified by REPIT:
    #     <gpt-number>  <gpt-name>  <friendly-name> <conf-defaults>     <crypto-footer>
    initPartition   11  TOMBSTONES  tombstones      "same keep ext4"    0
    initPartition   12  CACHE       cache           "same keep ext4"    0
    initPartition   13  SYSTEM      system          "same keep ext4"    0
    initPartition   14  HIDDEN      preload         "same keep ext4"    0
    initPartition   15  OTA         ota             "same keep raw"     0
    initPartition   16  USERDATA    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 11 16)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=16

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 256 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    heapAlignment=$(( 4 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 11 16)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 10)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
