#####################################################
# Lanchon REPIT - File System Handler               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### vfat

checkTools_fs_vfat() {
    # only require tools if actually needed
    #checkTool mkdosfs
    #checkTool dosfsck
    :
}

processPar_vfat_wipe_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    info "will format the partition in vfat"
    checkTool mkdosfs

}

processPar_vfat_wipe_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    processParRecreate $n $oldStart $oldSize $newStart $newSize
    info "formatting the partition in vfat"
    mkdosfs -I $dev

}

checkFs_vfat() {

    local n=$1
    local dev=$2

    info "checking the file system"
    # the -w flag is used here to bound memory use
    if ! dosfsck -pw $dev; then
        info "errors detected, retrying the file system check"
        if ! dosfsck -pw $dev; then
            fatal "file system errors in $(parName $n) could not be automatically fixed"
        fi
    fi

}

processPar_vfat_keep_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    checkTool dosfsck
    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        info "will move/resize the vfat partition"
    fi
    checkFs_vfat $@

}

processPar_vfat_keep_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        info "moving/resizing the vfat partition"
        runParted resize $n $newStart $(( newStart + newSize - 1 ))
        rereadParTable
        checkFs_vfat $@
    fi

}
