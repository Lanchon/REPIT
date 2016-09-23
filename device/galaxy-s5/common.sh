#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### galaxy-s5

# This port was possible thanks to the invaluable help of wecip.

# Disk /dev/block/mmcblk0: 30777344 sectors, 14.7 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 128 entries
# First usable sector is 34, last usable sector is 30777310
# Total free space is 8158 sectors (4.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1            8192           38911   15.0 MiB    8300  apnhlos
#    2           38912          156543   57.4 MiB    0700  modem
#    3          156544          157567   512.0 KiB   FFFF  sbl1
#    4          157568          157695   64.0 KiB    FFFF  dbi
#    5          157696          157759   32.0 KiB    FFFF  ddr
#    6          157760          161855   2.0 MiB     FFFF  aboot
#    7          161856          162879   512.0 KiB   FFFF  rpm
#    8          162880          163903   512.0 KiB   FFFF  tz
#    9          163904          170047   3.0 MiB     FFFF  fsg
#   10          170048          184319   7.0 MiB     FFFF  pad
#   11          184320          204799   10.0 MiB    FFFF  param
#   12          204800          233471   14.0 MiB    8300  efs
#   13          233472          239615   3.0 MiB     FFFF  modemst1
#   14          239616          245759   3.0 MiB     FFFF  modemst2
#   15          245760          272383   13.0 MiB    FFFF  boot
#   16          272384          303103   15.0 MiB    FFFF  recovery
#   17          303104          329727   13.0 MiB    FFFF  fota
#   18          329728          344045   7.0 MiB     8300  backup
#   19          344046          344047   1024 bytes  FFFF  fsc
#   20          344048          344063   8.0 KiB     FFFF  ssd
#   21          344064          360447   8.0 MiB     8300  persist
#   22          360448          378879   9.0 MiB     8300  persdata
#   23          378880         5498879   2.4 GiB     8300  system
#   24         5498880         5908479   200.0 MiB   8300  cache
#   25         5908480         6010879   50.0 MiB    8300  hidden
#   26         6010880        30777310   11.8 GiB    8300  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=1G-cache=32M+wipe-preload=min+wipe-data=max"

device_init() {

    device_checkDevice

    # the block device on which REPIT will operate (only one device is supported):

    #sdev=/sys/devices/msm_sdcc.1/mmc_host/mmc0/mmc0:0001/block/mmcblk0
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
    initPartition   23  system      system          "same keep ext4"    0
    initPartition   24  cache       cache           "same keep ext4"    0
    initPartition   25  hidden      preload         "same keep ext4"    0
    initPartition   26  userdata    data            "same keep ext4"    $footerSize

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 23 26)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=26

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
    heapPartitions="$(seq 23 26)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 22)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
