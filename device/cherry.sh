#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### cherry

# This port was possible thanks to the invaluable help of jerryhou85.

# Disk /dev/block/mmcblk0: 15269888 sectors, 7.3 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 24 entries
# First usable sector is 34, last usable sector is 15269854
# Partitions will be aligned on 1-sector boundaries
# Total free space is 16350 sectors (8.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1              34            1057   512.0 KiB   FFFF  sbl1
#    2            1058            2081   512.0 KiB   FFFF  hyp
#    3            8192            8255   32.0 KiB    FFFF  sec
#    4            8256            8319   32.0 KiB    FFFF  DDR
#    5           16384           17407   512.0 KiB   FFFF  rpm
#    6           17408           18431   512.0 KiB   FFFF  tz
#    7           18432           28543   4.9 MiB     FFFF  aboot
#    8           28544           30591   1024.0 KiB  FFFF  pad
#    9           30592          161663   64.0 MiB    FFFF  oeminfo
#   10          161664          169855   4.0 MiB     FFFF  modemst1
#   11          169856          178047   4.0 MiB     FFFF  modemst2
#   12          180224          376831   96.0 MiB    FFFF  modem
#   13          376832          385023   4.0 MiB     FFFF  fsg
#   14          385024          389119   2.0 MiB     FFFF  fsc
#   15          389120          393215   2.0 MiB     FFFF  ssd
#   16          393216          524287   64.0 MiB    FFFF  log
#   17          524288          589823   32.0 MiB    FFFF  persist
#   18          589824          630783   20.0 MiB    FFFF  boot
#   19          630784          679935   24.0 MiB    FFFF  recovery
#   20          679936         2252799   768.0 MiB   FFFF  cust
#   21         2252800         2777087   256.0 MiB   FFFF  cache
#   22         2777088         2785279   4.0 MiB     FFFF  misc
#   23         2785280         6455295   1.8 GiB     FFFF  system
#   24         6455296        15269854   4.2 GiB     0700  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="cust=min+wipe-cache=32M+wipe-system=1G-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:cherry:*) ;;
        *:Che1-CL20:*) ;;
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
    initPartition   20  cust        cust            "same keep ext4"    0
    initPartition   21  cache       cache           "same keep ext4"    0
    initPartition   22  misc        misc            "same keep raw"     0
    initPartition   23  system      system          "same keep ext4"    0
    initPartition   24  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="20 21 23 24"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=24

    # the set of defined heaps:
    allHeaps="main"

    # the partition data move chunk size (must fit in memory):
    moveDataChunkSize=$(( 512 * MiB ))

    # only call this if you will later use $deviceHeapStart or $deviceHeapEnd:
    detectBlockDeviceHeapRange

    # the size of partitions configured with the 'min' keyword:
    #heapMinSize=$(( 8 * MiB ))
    
    # the partition alignment:
    heapAlignment=$(( 4 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 20 24)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 19)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
