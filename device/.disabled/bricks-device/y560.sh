#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### y560

# This port was possible thanks to the invaluable help of macio525.

# Disk /dev/block/mmcblk0: 15269888 sectors, 7.3 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 32 entries
# First usable sector is 34, last usable sector is 15269854
# Total free space is 332856 sectors (162.5 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1          131072          262143   64.0 MiB    0700  modem
#    2          262144          263167   512.0 KiB   FFFF  sbl1
#    3          263168          264191   512.0 KiB   FFFF  sbl1bak
#    4          264192          266239   1024.0 KiB  FFFF  aboot
#    5          266240          268287   1024.0 KiB  FFFF  abootbak
#    6          268288          269311   512.0 KiB   FFFF  rpm
#    7          269312          270335   512.0 KiB   FFFF  rpmbak
#    8          270336          271871   768.0 KiB   FFFF  tz
#    9          271872          273407   768.0 KiB   FFFF  tzbak
#   10          273408          275455   1024.0 KiB  0700  pad
#   11          275456          278527   1.5 MiB     FFFF  modemst1
#   12          278528          281599   1.5 MiB     FFFF  modemst2
#   13          281600          283647   1024.0 KiB  FFFF  misc
#   14          283648          283649   1024 bytes  FFFF  fsc
#   15          283650          283665   8.0 KiB     FFFF  ssd
#   16          283666          304145   10.0 MiB    FFFF  splash
#   17          393216          393279   32.0 KiB    FFFF  DDR
#   18          393280          396351   1.5 MiB     FFFF  fsg
#   19          396352          396383   16.0 KiB    FFFF  sec
#   20          396384          461919   32.0 MiB    FFFF  boot
#   21          461920          527455   32.0 MiB    FFFF  persist
#   22          527456         4538259   1.9 GiB     FFFF  system
#   23         4538260         5062547   256.0 MiB   FFFF  cache
#   24         5062548         5128083   32.0 MiB    FFFF  recovery
#   25         5128084         5130131   1024.0 KiB  FFFF  devinfo
#   26         5242880         5243903   512.0 KiB   FFFF  keystore
#   27         5243904         5374975   64.0 MiB    FFFF  oem
#   28         5374976         5375999   512.0 KiB   FFFF  config
#   29         5376000        15269854   4.7 GiB     FFFF  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=1G-cache=32M+wipe-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:y560:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/soc.0/7824900.sdhci/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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
    initPartition   22  system      system          "same keep ext4"    0
    initPartition   23  cache       cache           "same keep ext4"    0
    initPartition   24  recovery    recovery        "same keep raw"     0
    initPartition   25  devinfo     devinfo         "same keep raw"     0
    initPartition   26  keystore    keystore        "same keep raw"     0
    initPartition   27  oem         oem             "same keep raw"     0
    initPartition   28  config      config          "same keep raw"     0
    initPartition   29  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="22 23 29"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=29

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 256 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    #heapAlignment=$(( 2 * 1024 / sectorSize ))     # stock alignment of the heap partitions is 2 KiB !!!
    heapAlignment=$(( 1 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 22 29)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 21)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
