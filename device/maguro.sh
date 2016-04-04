#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### maguro

# This port was possible thanks to the invaluable help of thagringo.

# Disk /dev/block/mmcblk0: 30777344 sectors, 2740M
# Logical sector size: 512
# Disk identifier (GUID): 52444e41-494f-2044-4d4d-43204449534b
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30777310
#  
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1             256             511        128K   0700  xloader
#    2            1024            8191       3584K   0700  sbl
#    3            8192           49151       20.0M   0700  efs
#    4           49152           65535       8192K   0700  param
#    5           65536           73727       4096K   0700  misc
#    6           73728           81919       4096K   0700  dgs
#    7           81920           98303       8192K   0700  boot
#    8           98304          122751       11.9M   0700  recovery
# * 13          122752          122879       65536   0700  metadata
#    9          122880          155647       16.0M   0700  radio
#   10          155648         1495039        654M   0700  system
#   11         1495040         2379775        432M   0700  cache
#   12         2379776        30777309       13.5G   0700  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=1.0-cache=0.0605+wipe-data=same"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:maguro:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/platform/omap/omap_hsmmc.0/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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

    # the set of partitions that can be modified by REPIT:
    #     <gpt-number>  <gpt-name>  <friendly-name> <conf-defaults>     <crypto-footer>
    initPartition   10  system      system          "same keep ext4"    0
    initPartition   11  cache       cache           "same keep ext4"    0
    initPartition   12  userdata    data            "same keep ext4"    0

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 10 12)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=13

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 256 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    heapAlignment=$(( 1 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 10 12)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 9)        # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
