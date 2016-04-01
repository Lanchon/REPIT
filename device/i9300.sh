#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### i9300

# Disk /dev/block/mmcblk0: 30777344 sectors, 2740M
# Logical sector size: 512
# Disk identifier (GUID): 52444e41-494f-2044-4d4d-43204449534b
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30777310
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192           16383       4096K   0700  BOTA0
#    2           16384           24575       4096K   0700  BOTA1
#    3           24576           65535       20.0M   0700  EFS
#    4           65536           81919       8192K   0700  PARAM
#    5           81920           98303       8192K   0700  BOOT
#    6           98304          114687       8192K   0700  RECOVERY
#    7          114688          180223       32.0M   0700  RADIO
#    8          180224         2277375       1024M   0700  CACHE
#    9         2277376         5423103       1536M   0700  SYSTEM
#   10         5423104         6569983        560M   0700  HIDDEN
#   11         6569984         6586367       8192K   0700  OTA
#   12         6586368        30769151       11.5G   0700  USERDATA

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="cache=same-system=same-preload=same-ota=same-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:m0:*) ;;
        *:i9300:*) ;;
        *:GT-I9300:*) ;;
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
    initPartition    8  CACHE       cache           "same keep ext4"    0
    initPartition    9  SYSTEM      system          "same keep ext4"    0
    initPartition   10  HIDDEN      preload         "same keep ext4"    0
    initPartition   11  OTA         ota             "same keep raw"     0
    initPartition   12  USERDATA    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 8 12)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=12

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
    heapPartitions="$(seq 8 12)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 7)        # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
