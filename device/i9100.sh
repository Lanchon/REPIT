#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### i9100

device_makeFilenameConfig="system=1.0-data=same-sdcard=max-preload=min+wipe"

device_init() {

    # the block device on which REPIT will operate (only one device is supported):

    sdev=/sys/devices/platform/dw_mmc/mmc_host/mmc0/mmc0:0001/block/mmcblk0
    spar=$sdev/mmcblk0p

    ddev=/dev/block/mmcblk0
    dpar=/dev/block/mmcblk0p

    sectorSize=512      # in bytes

}

device_check() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:galaxys2:*) ;;
        *:i9100:*) ;;
        *:GT-I9100:*) ;;
        *:GT-I9100M:*) ;;
        *:GT-I9100P:*) ;;
        *:GT-I9100T:*) ;;
        *:SC-02C:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_initPartitions() {

    # the set of partitions that can be modified by REPIT:
    #     <gpt-number>  <gpt-name>  <friendly-name> <conf-defaults>
    initPartition    9  FACTORYFS   system          "same keep ext4"
    initPartition   10  DATAFS      data            "same keep ext4"
    initPartition   11  UMS         sdcard          "same keep vfat"
    initPartition   12  HIDDEN      preload         "same keep ext4"

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 9 12)"
    # for some partitions it may be unsafe to do anything besides moving them around; those should be left out of this set.

}

device_setup() {

    ### this is the first function that can access block devices and/or their metadata.

    # the number of partitions that the device must have:
    partitionCount=12

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 256 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    ### the following settings are actually per-heap, but can be defined here instead if their values are constant.

    # the unit in which the user configures partition sizes:
    #heapSizeUnit=$GiB
    # this defaults to GiB and should normally not be changed.
    
    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    # this defaults to 8 MiB, the smallest power-of-2 size that will fit a standard ext4 file system.
    # note: this setting only applies to the 'min' keyword; partition sizes all the way down to $heapSizeGranularity
    # can still be manually defined even if they are smaller than $heapMinSize.
    
    # the partition alignment:
    heapAlignment=$(( 4 * MiB ))
    # for best results it is recommended that you use the same alignment chosen by the device OEM.
    # you can determine its value by analyzing the stock partitioning, for example with this command:
    # > parted /dev/block/whatever -s unit MiB print free
    # if in doubt, use 1 or 4 MiB.
    
    # user-configured partition sizes will be rounded (to nearest) to multiples of this value:
    #heapSizeGranularity=$heapAlignment
    # this defaults to $heapAlignment (in device_setup only) and should normally not be changed.

}

device_setupHeap_main() {

    # each heap is a set of partitions that are physically contiguous in the block device.
    # all partition manipulation works exclusively within a heap.

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 9 12)"

    # the disk area (as a sector range) to use for the heap partitions:
    # (the sector range is from heapStart to heapEnd-1 inclusive.)

    #heapStart=$deviceHeapStart     # the first usable sector of the device
    heapStart=$(parOldEnd 8)        # or one past the end of a specific partition
    #heapStart=344064               # or a fixed sector number

    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device
    #heapEnd=$(parOldStart 13)      # or the start of a specific partition
    #heapEnd=30769152               # or a fixed sector number

}

### code after this comment is old and no longer used. it is here for documentation purposes only.

device_detectBlockDeviceSize_i9100() {

    # this is unused code from when detectBlockDeviceHeapRange had not yet been implemented.
    # it is here for documentation purposes only, ports to other devices should delete this function.

    info "detecting eMMC size"

    local deviceSize=$(cat $sdev/size)
    local heapEnd8GB=15261696
    local heapEnd16GB=30769152
    local heapEnd32GB=62513152
    if [ $(( deviceSize < heapEnd8GB )) -ne 0 ]; then
        fatal "eMMC size too small"
    elif [ $(( deviceSize < heapEnd16GB )) -ne 0 ]; then
        heapEnd=$heapEnd8GB
        info "eMMC size is 8 GB"
    elif [ $(( deviceSize < heapEnd32GB )) -ne 0 ]; then
        heapEnd=$heapEnd16GB
        info "eMMC size is 16 GB"
    else
        heapEnd=$heapEnd32GB
        info "eMMC size is 32 GB"
    fi

}

device_configureStockLayout_i9100() {

    # this is unused code from when the configuration parser had not yet been implemented.
    # it is here for documentation purposes only, ports to other devices should delete this function.

    # stock partition layout for i9100:

    system_size=0.5
    data_size=2
    #sdcard_size=11.5078
    sdcard_size=max
    preload_size=0.5

    system_fs=ext4
    data_fs=ext4
    sdcard_fs=vfat
    preload_fs=ext4

}
