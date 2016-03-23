#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### janice

# Disk /dev/block/mmcblk0: 15269888 sectors, 3360M
# Logical sector size: 512
# Disk identifier (GUID): 52444e41-494f-2044-4d4d-43204449534b
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 15269854
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1           71680          104447       16.0M   0700  PARAM
#    2           28672           61439       16.0M   0700  Modem FS
#    3          206848         1460223        612M   0700  SYSTEM
#    4         5654528         6281215        306M   0700  CACHEFS
#    5         1460224         5654527       2048M   0700  DATAFS
#    6            3072            6143       1536K   0700  CSPSA FS
#    7            8192           28671       10.0M   0700  EFS
#    8         7038976        15251455       4010M   0700  UMS
#    9         6281216         6936575        320M   0700  HIDDEN
#   10            1024            3071       1024K   0700  PIT
#   11         6936576         7038975       50.0M   0700  Fota
#   12          104448          108543       2048K   0700  IPL Modem
#   13          108544          141311       16.0M   0700  Modem
#   14           63488           67583       2048K   0700  SBL
#   15          141312          174079       16.0M   0700  Kernel
#   16           67584           71679       2048K   0700  SBL_2
#   17          174080          206847       16.0M   0700  Kernel2
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#   10            1024            3071       1024K   0700  PIT
#    6            3072            6143       1536K   0700  CSPSA FS
#    7            8192           28671       10.0M   0700  EFS
#    2           28672           61439       16.0M   0700  Modem FS
#   14           63488           67583       2048K   0700  SBL
#   16           67584           71679       2048K   0700  SBL_2
#    1           71680          104447       16.0M   0700  PARAM
#   12          104448          108543       2048K   0700  IPL Modem
#   13          108544          141311       16.0M   0700  Modem
#   15          141312          174079       16.0M   0700  Kernel
#   17          174080          206847       16.0M   0700  Kernel2
#    3          206848         1460223        612M   0700  SYSTEM
#    5         1460224         5654527       2048M   0700  DATAFS
#    4         5654528         6281215        306M   0700  CACHEFS
#    9         6281216         6936575        320M   0700  HIDDEN
#   11         6936576         7038975       50.0M   0700  Fota
#    8         7038976        15251455       4010M   0700  UMS

device_makeFlashizeEnv="twrp2-arm"

device_makeFilenameConfig="system=same-data=3.0-cache=same-preload=same-fota=same-sdcard=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:janice:*) ;;
        *:i9070:*) ;;
        *:GT-I9070:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/sdi2/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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
    initPartition    3  SYSTEM      system          "same keep ext4"    0
    initPartition    5  DATAFS      data            "same keep ext4"    $footerSize
    initPartition    4  CACHEFS     cache           "same keep ext4"    0
    initPartition    9  HIDDEN      preload         "same keep ext4"    0
    initPartition   11  Fota        fota            "same keep raw"     0
    initPartition    8  UMS         sdcard          "same keep vfat"    0

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="3 5 4 9 11 8"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=17

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 128 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    heapAlignment=$(( 1 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="3 5 4 9 11 8"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 17)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
