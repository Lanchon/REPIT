#####################################################
# Lanchon REPIT - File System Handler               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### raw

checkTools_fs_raw() {
    # only require tools if actually needed
    :
}

processPar_raw_wipe_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    fatal "cannot wipe raw partitions"

}

processPar_raw_keep_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newSize != oldSize )) -ne 0 ]; then
        fatal "cannot resize raw partitions"
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "will move the raw partition"
    fi

}

processPar_raw_keep_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newSize != oldSize )) -ne 0 ]; then
        fatal "assertion failed: cannot resize raw partitions"
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "moving the raw partition"
        processParMove $n $oldStart $newStart $oldSize
    fi

}
