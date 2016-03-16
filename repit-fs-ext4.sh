#####################################################
# Lanchon REPIT - File System Handler               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### ext4

checkTools_fs_ext4() {
    # only require tools if actually needed
    #checkTool mke2fs
    #checkTool e2fsck
    #checkTool resize2fs
    :
}

processPar_ext4_wipe_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    info "will format the partition in ext4 and trim it"
    checkTool mke2fs

}

processPar_ext4_wipe_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    local footerSize=$(parFooterSize $n)
    local newFsSize=$(( newSize - footerSize ))

    processParRecreate $n $oldStart $oldSize $newStart $newSize
    processParWipeCryptoFooter $n $newStart $newSize $footerSize
    info "formatting the partition in ext4 and trimming it"
    mke2fs -q -t ext4 -E discard $dev ${newFsSize}s

}

checkFs_ext4() {

    local n=$1
    local dev=$2

    info "checking and trimming the file system"
    (set +e; e2fsck -fp -E discard $dev)
    case "$?" in
        0)
            ;;
        1)
            info "file system errors in $(parName $n) were fixed"
            ;;
        2|3)
            info "file system errors in $(parName $n) were fixed, but a reboot is needed before continuing"
            fatal "reboot needed: please reboot and retry the process to continue"
            ;;
        *)
            fatal "file system errors in $(parName $n) could not be automatically fixed (try running 'e2fsck -f $dev')"
            ;;
    esac    

}

processPar_ext4_keep_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "will move the ext4 partition"
        warning "moving a big ext4 partition can take a very long time; it requires copying the complete partition, including its free space"
    fi
    if [ $(( newSize != oldSize )) -ne 0 ]; then
        info "will resize the ext4 partition"
        #checkTool resize2fs
    fi
    if [ $(( newSize == oldSize )) -ne 0 ]; then
        info "will resize the ext4 file system if needed to fit its partition"
        #checkTool resize2fs
    fi
    checkTool e2fsck
    checkTool resize2fs
    checkFs_ext4 $n $dev

}

processPar_ext4_keep_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    local footerSize=$(parFooterSize $n)
    local newFsSize=$(( newSize - footerSize ))

    # note: REPIT should not be able to start on encrypted phones due to the block device being locked.

    local moveSize=$oldSize
    if [ $(( newSize < oldSize )) -ne 0 ]; then
        info "shrinking the ext4 file system"
        resize2fs -f $dev ${newFsSize}s
        info "shrinking the partition entry"
        processParRecreate $n $oldStart $oldSize $oldStart $newSize
        processParWipeCryptoFooter $n $oldStart $newSize $footerSize
        checkFs_ext4 $n $dev
        moveSize=$newSize
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "moving the ext4 partition"
        processParMove $n $oldStart $newStart $moveSize
        checkFs_ext4 $n $dev
    fi
    if [ $(( newSize > oldSize )) -ne 0 ]; then
        info "enlarging the partition entry"
        processParRecreate $n $newStart $oldSize $newStart $newSize
        processParWipeCryptoFooter $n $newStart $newSize $footerSize
        info "enlarging the ext4 file system"
        resize2fs -f $dev ${newFsSize}s
        checkFs_ext4 $n $dev
    fi
    if [ $(( newSize == oldSize )) -ne 0 ]; then
        info "resizing the ext4 file system if needed to fit its partition"
        resize2fs -f $dev ${newFsSize}s
        checkFs_ext4 $n $dev
    fi

}
