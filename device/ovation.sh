#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### ovation

# # This port was possible thanks to the invaluable help of 149113.
# 
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
# Disk /dev/block/mmcblk0: 30535680 sectors, 14.6 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 3290B191-5EED-4A94-BFD4-0ECCA08BCEF4
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30535646
# Total free space is 29885 sectors (14.6 MiB)
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

device_makeFlashizeEnv="env/arm.zip"

#device_makeFilenameConfig="factory=same-system=1104M-cache=32M+wipe-data=same"
device_makeFilenameConfig="factory=same-system=1G-cache=112M+wipe-data=same"
#device_makeFilenameConfig="factory=32M-system=1G-cache=32M+wipe-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:ovation:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/platform/omap/omap_hsmmc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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
    initPartition    7  factory     factory         "same keep ext4"    0
    initPartition    8  system      system          "same keep ext4"    0
    initPartition    9  cache       cache           "same keep ext4"    0
    initPartition   10  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 7 10)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=10

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
    heapPartitions="$(seq 7 10)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 6)        # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
