#####################################################
# Lanchon REPIT - Generic Partition Tools           #
# Copyright 2016, Lanchon                           #
#####################################################

#####################################################
# Lanchon REPIT is free software licensed under     #
# the GNU General Public License (GPL) version 3    #
# and any later version.                            #
#####################################################

### recreate partition

processParRecreate() {
    local n=$1
    local oldStart=$2
    local oldSize=$3
    local newStart=$4
    local newSize=$5
    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        info "deleting current partition"
        runParted rm $n
        info "creating new partition"
        if runParted mkpart primary $newStart $(( $newStart + $newSize - 1 )); then
            info "naming the partition"
            runParted name $n $(parGet $n pname)
            rereadParTable
        else
            info "attempting to restore previous partition"
            runParted mkpart primary $oldStart $(( $oldStart + $oldSize - 1 ))
            info "naming the partition"
            runParted name $n $(parGet $n pname)
            rereadParTable
            fatal "unable to create new partition (previous partition was successfully restored)"
        fi
    fi
}

### move partition

moveDataChunk() {
    local n=$1
    local oldStart=$2
    local newStart=$3
    local size=$4
    echo "-----  moving $(printSizeMiB $size) chunk: $(printSizeMiB $oldStart) -> $(printSizeMiB $newStart)"
    # WARNING: dd has a dangerous 4 GiB wraparound bug!!!
    #dd if=$ddev of=$tchunk bs=$sectorSize skip=$oldStart count=$size conv=noerror,sync
    #dd if=$tchunk of=$ddev bs=$sectorSize seek=$newStart count=$size conv=noerror,sync
    info "creating temporary partition to read chunk at device offset $(printSizeMiB $oldStart)"
    runParted mkpart primary $oldStart $(( $oldStart + $size - 1 ))
    rereadParTable
    info "reading data"
    dd if=${dpar}$n of=$tchunk bs=$sectorSize conv=noerror,sync
    info "deleting the temporary partition"
    runParted rm $n
    info "creating temporary partition to write chunk at device offset $(printSizeMiB $newStart)"
    runParted mkpart primary $newStart $(( $newStart + $size - 1 ))
    rereadParTable
    info "writing data"
    dd if=$tchunk of=${dpar}$n bs=$sectorSize conv=noerror,sync
    info "deleting the temporary partition"
    runParted rm $n
    #rereadParTable
    rm -f $tchunk
    echo
}

moveData() {
    local pn=$1
    local oldStart=$2
    local newStart=$3
    local size=$4
    local chunk=$moveDataChunkSize
    local n
    local m
    if [ $(( newStart < oldStart )) -ne 0 ]; then
        info "moving data towards the beginning of the disk"
        echo
        m=0
        for n in $(seq -- 0 $chunk $(( size - chunk - 1 )) ); do
            moveDataChunk $pn $(( oldStart + n )) $(( newStart + n )) $chunk
            m=$(( $n + chunk ))
        done
        moveDataChunk $pn $(( oldStart + m )) $(( newStart + m )) $(( size - m ))
    fi
    if [ $(( newStart > oldStart )) -ne 0 ]; then
        info "moving data towards the end of the disk"
        echo
        m=$size
        for n in $(seq -- $(( size - chunk )) $(( - chunk )) 1); do
            moveDataChunk $pn $(( oldStart + n )) $(( newStart + n )) $chunk
            m=$n
        done
        moveDataChunk $pn $oldStart $newStart $m
    fi
}

processParMove() {

    local n=$1
    local oldStart=$2
    local newStart=$3
    local size=$4

    if [ $(( newStart != oldStart )) -ne 0 ]; then

#rereadParTable
#echo "#####  calculating MD5 hash of partition"
#md5sum ${dpar}$n

        # this does not work (so we manually dd data around instead)
        #runParted move $n $newStart $(( $newStart + $size - 1 ))
        #rereadParTable

        info "ensure that the destination partition can be created before starting the move"
        processParRecreate $n $oldStart $size $newStart $size
        #info "ensure no access if move is interrupted by deleting the partition"
        info "deleting the partition to workaround dd's 4 GiB wraparound bug"
        runParted rm $n
        #rereadParTable
        moveData $n $oldStart $newStart $size
        #info "recreating the partition"
        info "creating the final partition"
        runParted mkpart primary $newStart $(( $newStart + $size - 1 ))
        info "naming the partition"
        runParted name $n $(parGet $n pname)
        rereadParTable

##rereadParTable
#echo "#####  calculating MD5 hash of partition"
#md5sum ${dpar}$n

    fi

}

checkTools_processParMove() {
    checkTool dd
}
