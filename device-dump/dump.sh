#!/sbin/sh

#####################################################
# Lanchon REPIT                                     #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

run() {
    echo "=========================================================================================================="
    echo "$@"
    echo "----------------------------------------------------------------------------------------------------------"
    "$@"
    local code=$?
    echo
    return $code
}

run getprop ro.product.device
run grep ro.product.device default.prop

run getprop ro.build.product
run grep ro.build.product default.prop

checkTool() {
    echo "$1:"
    echo "        $(which "$1")"
}

checkTools() {

    checkTool parted
    checkTool sort
    checkTool blockdev
    checkTool sed
    checkTool awk
    checkTool readlink
    checkTool basename
    checkTool dirname
    checkTool dd

    checkTool fdisk
    checkTool gdisk
    checkTool sfdisk
    checkTool sgdisk

    #checkTools_fs_ext4
    #checkTools_fs_vfat
    #checkTools_fs_raw

}

checkTools_fs_ext4() {
    checkTool mke2fs
    checkTool e2fsck
    checkTool resize2fs
}

checkTools_fs_vfat() {
    checkTool mkdosfs
    checkTool mkfs.fat
    checkTool dosfsck
    checkTool fsck.fat
}

checkTools_fs_f2fs() {
    checkTool mkfs.f2fs
    checkTool fsck.f2fs
}

checkTools_fs_swap() {
    checkTool mkswap
}

checkTools_fs_raw() {
    :
}

run checkTools

run checkTools_fs_ext4
run checkTools_fs_vfat
run checkTools_fs_f2fs
run checkTools_fs_swap
run checkTools_fs_raw

run ls -l /sys/block/mmcblk0

run parted -s /dev/block/mmcblk0 unit MiB print free unit s print free
run sgdisk /dev/block/mmcblk0 --set-alignment 1 --print

run getprop
run cat /default.prop

run env
run set

run ls -lR /sbin

run ls -l /dev/block
run ls -l /sys/block

for device in /dev/block/*; do
    run parted -s "$device" unit MiB print free unit s print free &&
    run sgdisk "$device" --set-alignment 1 --print
done

run ls -lR /dev/block
run ls -lR /sys/block

#run ls -lR /dev
#run ls -lR /sys
