#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### galaxy-j5

# This port was possible thanks to the invaluable help of ajislav.

# Disk /dev/block/mmcblk0: 15269888 sectors, 7.3 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 15269854
# Total free space is 8165 sectors (4.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192           38911   15.0 MiB    0700  apnhlos
#    2           38912          156543   57.4 MiB    0700  modem
#    3          156544          157567   512.0 KiB   FFFF  sbl1
#    4          157568          157631   32.0 KiB    FFFF  ddr
#    5          157632          161727   2.0 MiB     FFFF  aboot
#    6          161728          162751   512.0 KiB   FFFF  rpm
#    7          162752          163775   512.0 KiB   FFFF  qsee
#    8          163776          164799   512.0 KiB   FFFF  qhee
#    9          164800          170943   3.0 MiB     FFFF  fsg
#   10          170944          170975   16.0 KiB    FFFF  sec
#   11          170976          192511   10.5 MiB    0700  pad
#   12          192512          212991   10.0 MiB    FFFF  param
#   13          212992          241663   14.0 MiB    8300  efs
#   14          241664          247807   3.0 MiB     FFFF  modemst1
#   15          247808          253951   3.0 MiB     FFFF  modemst2
#   16          253952          280575   13.0 MiB    FFFF  boot
#   17          280576          311295   15.0 MiB    FFFF  recovery
#   18          311296          336897   12.5 MiB    FFFF  fota
#   19          336898          351215   7.0 MiB     8300  backup
#   20          351216          357359   3.0 MiB     FFFF  fsc
#   21          357360          357375   8.0 KiB     FFFF  ssd
#   22          357376          373759   8.0 MiB     8300  persist
#   23          373760          374783   512.0 KiB   8300  persistent
#   24          374784          393215   9.0 MiB     8300  persdata
#   25          393216         4653055   2.0 GiB     8300  system
#   26         4653056         5062655   200.0 MiB   8300  cache
#   27         5062656         5206015   70.0 MiB    8300  hidden
#   28         5206016        15269847   4.8 GiB     8300  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=1.0-cache=0.0605+wipe-preload=min+wipe-data=max"

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
    initPartition   25  system      system          "same keep ext4"    0
    initPartition   26  cache       cache           "same keep ext4"    0
    initPartition   27  hidden      preload         "same keep ext4"    0
    initPartition   28  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 25 28)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=28

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
    heapPartitions="$(seq 25 28)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 24)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
