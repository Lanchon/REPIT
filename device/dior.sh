#####################################################
# Lanchon REPIT - Device Handler                    #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### dior

# This port was possible thanks to the invaluable help of jerryhou85.

# Caution: invalid backup GPT header, but valid main header; regenerating
# backup header from main header.
# 
# ****************************************************************************
# Caution: Found protective or hybrid MBR and corrupt GPT. Using GPT, but disk
# verification and recovery are STRONGLY recommended.
# ****************************************************************************
# Disk /dev/block/mmcblk0: 15269888 sectors, 7.3 GiB
# Logical sector size: 512 bytes
# Disk identifier (GUID): 98101B32-BBE2-4BF2-A06E-2BB33D000C20
# Partition table holds up to 32 entries
# First usable sector is 34, last usable sector is 15269854
# Total free space is 65546 sectors (32.0 MiB)
# 
# Number  Start (sector)    End (sector)  Size       Code  Name
#    1              34            4095   2.0 MiB     FFFF  sbl1
#    2            4096            8157   2.0 MiB     0700  sbl1bak
#    3            8158           10205   1024.0 KiB  FFFF  rpm
#    4           10206           12253   1024.0 KiB  0700  rpmbak
#    5           12254           14301   1024.0 KiB  FFFF  tz
#    6           14302           16349   1024.0 KiB  0700  tzbak
#    7           16350           16365   8.0 KiB     FFFF  ssd
#    8           16366           18413   1024.0 KiB  FFFF  sdi
#    9           18414           20461   1024.0 KiB  FFFF  DDR
#   10           20462           28653   4.0 MiB     FFFF  aboot
#   11           28654           36845   4.0 MiB     0700  abootbak
#   12           36846           47085   5.0 MiB     8300  bk1
#   13           47086           55277   4.0 MiB     FFFF  misc
#   14           55278           71661   8.0 MiB     8300  logo
#   15           71662          131061   29.0 MiB    8300  bk2
#   16          131062          134133   1.5 MiB     FFFF  modemst1
#   17          134134          137205   1.5 MiB     FFFF  modemst2
#   18          137206          137207   1024 bytes  FFFF  fsc
#   19          137208          262133   61.0 MiB    8300  bk3
#   20          262134          265205   1.5 MiB     FFFF  fsg
#   21          265206          327669   30.5 MiB    8300  bk4
#   22          327670          393205   32.0 MiB    8300  bk5
#   23          393206          524277   64.0 MiB    0700  modem
#   24          524278          557045   16.0 MiB    FFFF  boot
#   25          557046          589813   16.0 MiB    FFFF  recovery
#   26          589814          655349   32.0 MiB    0700  persist
#   27          655350         2293749   800.0 MiB   0700  system
#   28         2293750         3080181   384.0 MiB   0700  cache
#   29         3145728        15269854   5.8 GiB     0700  userdata

device_makeFlashizeEnv="env/arm.zip"

#device_makeFilenameConfig="system=1.133-cache=0.031+wipe-data=same"
#device_makeFilenameConfig="system=max-cache=0.03125+wipe-data=same"

#device_makeFilenameConfig="system=1.0-cache=0.164+wipe-data=same"
#device_makeFilenameConfig="system=1.0-cache=max+wipe-data=same"

device_makeFilenameConfig="system=same-cache=0.03125+wipe-data=max"

device_checkDevice() {

    checkTool getprop

    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:dior:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac

}

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

    # the set of partitions that can be modified by REPIT:
    #     <gpt-number>  <gpt-name>  <friendly-name> <conf-defaults>     <crypto-footer>
    initPartition   27  system      system          "same keep ext4"    0
    initPartition   28  cache       cache           "same keep ext4"    0
    initPartition   29  userdata    data            "same keep ext4"    0

    # the set of modifiable partitions that can be configured by the user (overriding <conf-defaults>):
    configurablePartitions="$(seq 27 29)"

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
    heapAlignment=$(( 4 * MiB ))

}

device_setupHeap_main() {

    # the set of contiguous partitions that form this heap, in order of ascending partition start address:
    heapPartitions="$(seq 27 29)"

    # the disk area (as a sector range) to use for the heap partitions:
    heapStart=$(parOldEnd 26)       # one past the end of a specific partition
    heapEnd=$deviceHeapEnd          # one past the last usable sector of the device

}
