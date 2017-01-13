#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### serrano3gxx

# This port was possible thanks to the invaluable help of vaedasti.

# Disk /dev/block/mmcblk0: 15269888 sectors, 7.3 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 15269854
# Total free space is 8158 sectors (4.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192          131071   60.0 MiB    0700  modem
#    2          131072          131327   128.0 KiB   FFFF  sbl1
#    3          131328          131839   256.0 KiB   FFFF  sbl2
#    4          131840          132863   512.0 KiB   FFFF  sbl3
#    5          132864          136959   2.0 MiB     FFFF  aboot
#    6          136960          137983   512.0 KiB   FFFF  rpm
#    7          137984          139007   512.0 KiB   FFFF  tz
#    8          139008          164607   12.5 MiB    FFFF  pad
#    9          164608          180991   8.0 MiB     8300  param
#   10          180992          208895   13.6 MiB    8300  efs
#   11          208896          215039   3.0 MiB     FFFF  modemst1
#   12          215040          221183   3.0 MiB     FFFF  modemst2
#   13          221184          241663   10.0 MiB    FFFF  boot
#   14          241664          262143   10.0 MiB    FFFF  recovery
#   15          262144          282623   10.0 MiB    FFFF  fota
#   16          282624          296943   7.0 MiB     8300  backup
#   17          296944          303087   3.0 MiB     FFFF  fsg
#   18          303088          303103   8.0 KiB     FFFF  ssd
#   19          303104          319487   8.0 MiB     8300  persist
#   20          319488          344063   12.0 MiB    8300  persdata
#   21          344064         3416063   1.5 GiB     8300  system
#   22         3416064         3825663   200.0 MiB   8300  cache
#   23         3825664         4030463   100.0 MiB   8300  hidden
#   24         4030464        15269854   5.4 GiB     8300  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=1G-cache=32M+wipe-preload=min+wipe-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:serrano3g:*) ;;
        *:serrano3gxx:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

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
    initPartition   21  system      system          "same keep ext4"    0
    initPartition   22  cache       cache           "same keep ext4"    0
    initPartition   23  hidden      preload         "same keep ext4"    0
    initPartition   24  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 21 24)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=24

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
    heapPartitions="$(seq 21 24)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 20)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
