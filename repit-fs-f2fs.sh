#####################################################
# Lanchon REPIT - File System Handler               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### f2fs

checkTools_fs_f2fs() {
    # only require tools if actually needed
    #checkTool mkfs.f2fs
    #checkTool fsck.f2fs
    :
}

processPar_f2fs_wipe_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    info "will format the partition in f2fs and trim it"
    checkTool mkfs.f2fs

}

processPar_f2fs_wipe_wet() {

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
    info "formatting the partition in f2fs and trimming it"
    mkfs.f2fs -t 1 $dev ${newFsSize}

}

checkFs_f2fs() {

    local n=$1
    local dev=$2

    if [ -z "$(which fsck.f2fs)" ]; then

        warning "skipping file system check (tool 'fsck.f2fs' is not available)"

    else

        info "checking the file system"
        if ! fsck.f2fs -f $dev; then
            fatal "file system errors in $(parName $n) could not be fixed"
        fi

    fi

}

processPar_f2fs_keep_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newSize != oldSize )) -ne 0 ]; then
        fatal "cannot resize f2fs partitions"
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "will move the f2fs partition"
        warning "moving a big f2fs partition can take a very long time; it requires copying the complete partition, including its free space"
    fi

    #checkTool fsck.f2fs
    checkFs_f2fs $n $dev

}

processPar_f2fs_keep_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newSize != oldSize )) -ne 0 ]; then
        fatal "assertion failed: cannot resize f2fs partitions"
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "moving the f2fs partition"
        processParMove $n $oldStart $newStart $oldSize
        checkFs_f2fs $n $dev
    fi

}
