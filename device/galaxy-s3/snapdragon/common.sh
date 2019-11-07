#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2019, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### galaxy-s3/snapdragon

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=same-data=max-cache=32M+wipe"

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/platform/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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
    initPartition   14  system      system          "same keep ext4"    0
    initPartition   15  userdata    data            "same keep ext4"    $footerSize
    initPartition   16  persist     persist         "same keep raw"     0
    initPartition   17  cache       cache           "same keep ext4"    0

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="14 15 17"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=23

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 256 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    #detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    heapAlignment=$(( 4 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 14 17)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 13)       # one past the end of a specific partition
    heapEnd=$(parOldStart 18)       # the start of a specific partition

}
