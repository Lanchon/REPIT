#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2019, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### nexus-7-2013

# Disk /dev/block/mmcblk0: 61079552 sectors, 29.1 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 32 entries
# First usable sector is 34, last usable sector is 61079518
# Total free space is 1526010 sectors (745.1 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1          131072          306143   85.5 MiB    0700  radio
#    2          393216          399359   3.0 MiB     FFFF  modemst1
#    3          399360          405503   3.0 MiB     FFFF  modemst2
#    4          524288          554287   14.6 MiB    8300  persist
#    5          655360          656919   780.0 KiB   FFFF  m9kefs1
#    6          656920          658479   780.0 KiB   FFFF  m9kefs2
#    7          786432          787991   780.0 KiB   FFFF  m9kefs3
#    8          787992          794135   3.0 MiB     FFFF  fsg
#    9          917504          920503   1.5 MiB     FFFF  sbl1
#   10          920504          923503   1.5 MiB     FFFF  sbl2
#   11          923504          927599   2.0 MiB     FFFF  sbl3
#   12          927600          937839   5.0 MiB     FFFF  aboot
#   13          937840          938863   512.0 KiB   FFFF  rpm
#   14         1048576         1081343   16.0 MiB    FFFF  boot
#   15         1179648         1180671   512.0 KiB   FFFF  tz
#   16         1180672         1180673   1024 bytes  FFFF  pad
#   17         1180674         1183673   1.5 MiB     FFFF  sbl2b
#   18         1183674         1187769   2.0 MiB     FFFF  sbl3b
#   19         1187770         1198009   5.0 MiB     FFFF  abootb
#   20         1198010         1199033   512.0 KiB   FFFF  rpmb
#   21         1199034         1200057   512.0 KiB   FFFF  tzb
#   22         1310720         3031039   840.0 MiB   8300  system
#   23         3031040         4177919   560.0 MiB   8300  cache
#   24         4194304         4196351   1024.0 KiB  FFFF  misc
#   25         4325376         4345855   10.0 MiB    FFFF  recovery
#   26         4456448         4456463   8.0 KiB     FFFF  DDR
#   27         4456464         4456479   8.0 KiB     FFFF  ssd
#   28         4456480         4456481   1024 bytes  FFFF  m9kefsc
#   29         4587520         4587583   32.0 KiB    FFFF  metadata
#   30         4718592        61079518   26.9 GiB    8300  userdata

device_makeFlashizeEnv="env/arm.zip"

device_makeFilenameConfig="system=max-cache=32M+wipe"

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
    initPartition   22  system      system          "same keep ext4"    0
    initPartition   23  cache       cache           "same keep ext4"    0

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 22 23)"

}

device_setup() {

    # the number of partitions that the device must have:
    partitionCount=30

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
    heapPartitions="$(seq 22 23)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=1310720
    heapEnd=4194304

}
