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
    return $?
}

run getprop ro.product.device
run grep ro.product.device default.prop

run getprop ro.build.product
run grep ro.build.product default.prop

run getprop
run cat /default.prop

run set

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

    #checkTools_fs_ext4
    #checkTools_fs_vfat

}

checkTools_fs_ext4() {
    checkTool mke2fs
    checkTool e2fsck
    checkTool resize2fs
}

checkTools_fs_vfat() {
    checkTool mkdosfs
    checkTool dosfsck
}

run checkTools

run checkTools_fs_ext4
run checkTools_fs_vfat

run ls -lR /sbin

run ls -l /dev/block

run_fdisk() {
    echo p | fdisk -u $1
}

for device in /dev/block/*; do
    run parted -s $device unit MiB print free unit s print free
    run run_fdisk $device
done

run ls -lR /dev/block
run ls -lR /sys/devices/platform/*mmc*

run ls -lR /dev
run ls -lR /sys
