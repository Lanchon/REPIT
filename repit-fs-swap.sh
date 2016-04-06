#####################################################
# Lanchon REPIT - File System Handler               #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### swap

checkTools_fs_swap() {
    # only require tools if actually needed
    #checkTool mkswap
    :
}

processPar_swap_wipe_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    info "will format the partition as swap area"
    checkTool mkswap

}

processPar_swap_wipe_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    processParRecreate $n $oldStart $oldSize $newStart $newSize
    info "formatting the partition as swap area"
    mkswap $dev

}

processPar_swap_keep_dry() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        fatal "cannot move or resize swap partitions "\
"(it makes no sense, please wipe the partition instead; note that you can still move the contents of any partition by using the 'raw' type)"
    fi

}

processPar_swap_keep_wet() {

    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6

    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        fatal "assertion failed: cannot move or resize swap partitions"
    fi

}
