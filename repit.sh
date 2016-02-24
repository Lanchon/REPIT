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

set -e

version="2016-02-16"
deviceName="i9100"

sdev=/sys/devices/platform/dw_mmc/mmc_host/mmc0/mmc0:0001/block/mmcblk0
spar=$sdev/mmcblk0p

ddev=/dev/block/mmcblk0
dpar=/dev/block/mmcblk0p

tdir=/tmp/lanchon-repit
tchunk=$tdir/chunk.tmp

tpar=$tdir/partition-info/p

fatal() {
    echo
    >&2 echo "FATAL:" "$@"
    exit 1
}

warning() {
    >&2 echo "WARNING:" "$@"
}

info() {
    echo "info:" "$@"
}

printSizeMiB() {
    local size="$1"
    echo "$(( size / (1024 * 2) )) MiB"
}

checkTool() {
    #info "checking tool: $1"
    if [ -z "$(which "$1")" ]; then
        fatal "required tool '$1' missing (please use a recent version of TWRP to run this package)"
    fi
}

runParted() {
    parted -s $ddev unit s "$@"
}

rereadParTable() {
    local hint="$1"
    info "rereading partition table"
    sync
    blockdev --flushbufs $ddev
    if ! blockdev --rereadpt $ddev; then
        fatal "unable to reread the partition table${hint}"
    fi
    sleep 1
}

parOldStart() {
    cat ${spar}$1/start
}

parNewStart() {
    cat ${tpar}$1/start
}

parOldSize() {
    cat ${spar}$1/size
}

parNewSize() {
    cat ${tpar}$1/size
}

parOldEnd() {
    echo $(( $(parOldStart $1) + $(parOldSize $1) ))
}

parNewEnd() {
    echo $(( $(parNewStart $1) + $(parNewSize $1) ))
}

parGet() {
    cat ${tpar}$1/$2
}

parSet() {
    echo -n "$3" >${tpar}$1/$2
}

parName() {
    echo -n "partition #$1 /$(parGet $1 mname) ($(parGet $1 pname))"
}

initPar() {

    local n=$1

    mkdir -p ${tpar}$n
    $(parSet $n pname $2)
    $(parSet $n mname $3)
    if [ $(( $(parOldStart $n) <= 0 )) -ne 0 ]; then
        fatal "$(parName $n): invalid start"
    fi
    if [ $(( $(parOldSize $n) <= 0 )) -ne 0 ]; then
        fatal "$(parName $n): invalid size"
    fi

}

initParNew() {

    local n=$1
    local size="$2"
    local content="$3"
    local fs="$4"
    local defaultFs="$5"

    if [ -z "$size" ]; then
        fatal "$(parName $n): undefined new size"
    fi
    if [ -z "$content" ]; then
        fatal "$(parName $n): undefined content policy"
    fi
    if [ -z "$fs" ]; then
        fs=$defaultFs
    fi

    # size granularity: MiB
    # size unit: GiB
    local granularity=2048
    local unit=1024
    case "$size" in
        same)
            size=$(parOldSize $n)
            ;;
        min)
            size=$minParSize
            ;;
        max)
            size=0
            ;;
        *)
            size=$(awk "BEGIN {print int(($size) * $unit + 0.5)}")
            size=$(( ($size) * $granularity ))
            if [ $(( $size < minParSize )) -ne 0 ]; then
                fatal "$(parName $n): invalid new size"
            fi
            ;;
    esac    

    case "$content" in
        keep)
            ;;
        wipe)
            ;;
        *)
            fatal "$(parName $n): invalid content policy"
            ;;
    esac    

    case "$fs" in
        ext4)
            ;;
        vfat)
            ;;
        *)
            fatal "$(parName $n): invalid file system type"
            ;;
    esac    

    $(parSet $n size $size)
    $(parSet $n content $content)
    $(parSet $n fs $fs)

}

setup() {

    rm -rf $tdir

    checkTool parted
    checkTool sort
    checkTool blockdev
    checkTool awk

    info "unmounting all partitions"

    
    local dev
    for dev in $(grep -ow "^${dpar}[0-9]*" /proc/mounts | sort -u); do
        umount $dev
    done

    # rereadParTable requires everything unmounted
    rereadParTable

    info "detecting eMMC size"

    # disk area to use for movable partitions:
    heapStart=344064
    heapEnd=

    if [ ! -e $sdev ]; then
        fatal "eMMC device not found"
    fi
    local deviceSize=$(cat $sdev/size)
    local heapEnd8GB=15261696
    local heapEnd16GB=30769152
    local heapEnd32GB=62513152
    if [ $(( deviceSize < heapEnd8GB )) -ne 0 ]; then
        fatal "eMMC size too small"
    elif [ $(( deviceSize < heapEnd16GB )) -ne 0 ]; then
        heapEnd=$heapEnd8GB
        info "eMMC size is 8 GB"
    elif [ $(( deviceSize < heapEnd32GB )) -ne 0 ]; then
        heapEnd=$heapEnd16GB
        info "eMMC size is 16 GB"
    else
        heapEnd=$heapEnd32GB
        info "eMMC size is 32 GB"
    fi

    info "checking existing partition layout"

    local n
    for n in $(seq 1 12); do
        if [ ! -e ${spar}$n ]; then
            fatal "missing partition #$n"
        fi
    done

    if [ -e ${spar}$(( 12 + 1 )) ]; then
        fatal "unexpected partition #$(( 12 + 1 ))"
    fi

    initPar  8 MODEM     modem
    initPar  9 FACTORYFS system
    initPar 10 DATAFS    data
    initPar 11 UMS       sdcard
    initPar 12 HIDDEN    preload

    if [ $(( $(parOldEnd 8) != $heapStart )) -ne 0 ]; then
        fatal "$(parName 8): unexpected end: $(parOldEnd 8)"
    fi
    
    local pn
    local gap
    for n in $(seq 9 12); do
        info "current size: $(parName $n): $(printSizeMiB $(parOldSize $n))"
        pn=$(( $n - 1 ))
        gap=$(( $(parOldStart $n) - $(parOldEnd $pn) ))
        if [ $(( gap < 0 )) -ne 0 ]; then
            fatal "layout reversal between $(parName $pn) and $(parName $n)"
        fi
        if [ $(( gap > 0 )) -ne 0 ]; then
            warning "unallocated space between $(parName $pn) and $(parName $n)"
        fi
    done
    gap=$(( heapEnd - $(parOldEnd 12) ))
    if [ $(( gap < 0 )) -ne 0 ]; then
        warning "the existing partition layout uses more space than expected"
    fi
    if [ $(( gap > 0 )) -ne 0 ]; then
        warning "the existing partition layout has unused space at the end of the disk"
    fi

    info "checking new partition layout"

    # minimum partition size: 8 MiB
    minParSize=$(( 8 * 1024 * 2 ))

    initParNew  9  "$system_size"  "$system_content"  "$system_fs" ext4
    initParNew 10    "$data_size"    "$data_content"    "$data_fs" ext4
    initParNew 11  "$sdcard_size"  "$sdcard_content"  "$sdcard_fs" vfat
    initParNew 12 "$preload_size" "$preload_content" "$preload_fs" ext4

    local totalSize=$(( $heapEnd - $heapStart ))
    for n in $(seq 9 12); do
        totalSize=$(( totalSize - $(parNewSize $n) ))
    done
    local maxPar
    for n in $(seq 9 12); do
        if [ "$(parNewSize $n)" -eq "0" ]; then
            if [ -n "$maxPar" ]; then
                fatal "more than one partition has its size set to 'max'"
            fi
            maxPar=$n
            if [ $(( $totalSize < minParSize )) -ne 0 ]; then
                fatal "$(parName $n): invalid new size"
            fi
            $(parSet $n size $totalSize)
        fi
        info "new size: $(parName $n): $(printSizeMiB $(parNewSize $n))"
    done

    $(parSet 9 start $heapStart)
    for n in $(seq 10 12); do
        $(parSet $n start $(parNewEnd $(( $n - 1 ))))
    done

    gap=$(( $heapEnd - $(parNewEnd 12) ))
    if [ $(( gap < 0 )) -ne 0 ]; then
        fatal "the new partition layout requires more space than available"
    fi
    if [ $(( gap > 0 )) -ne 0 ]; then
        warning "the new partition layout has unused space at the end of the disk"
    fi

}

### general

processParRecreate() {
    local n=$1
    local oldStart=$2
    local oldSize=$3
    local newStart=$4
    local newSize=$5
    if [ $(( newStart != oldStart || newSize != oldSize )) -ne 0 ]; then
        info "deleting the partition"
        runParted rm $n
        info "recreating the partition"
        runParted mkpart primary $newStart $(( $newStart + $newSize - 1 ))
        info "naming the partition"
        runParted name $n $(parGet $n pname)
        rereadParTable
    fi
}

moveDataChunk() {
    local n=$1
    local oldStart=$2
    local newStart=$3
    local size=$4
    echo "-----  moving $(printSizeMiB $size) chunk: $(printSizeMiB $oldStart) -> $(printSizeMiB $newStart)"
    # WARNING: dd has a dangerous 4 GiB wraparound bug!!!
    #dd if=$ddev of=$tchunk bs=512 skip=$oldStart count=$size conv=noerror,sync
    #dd if=$tchunk of=$ddev bs=512 seek=$newStart count=$size conv=noerror,sync
    info "creating temporary partition to read chunk at device offset $(printSizeMiB $oldStart)"
    runParted mkpart primary $oldStart $(( $oldStart + $size - 1 ))
    rereadParTable
    info "reading data"
    dd if=${dpar}$n of=$tchunk bs=512 conv=noerror,sync
    info "deleting the temporary partition"
    runParted rm $n
    info "creating temporary partition to write chunk at device offset $(printSizeMiB $newStart)"
    runParted mkpart primary $newStart $(( $newStart + $size - 1 ))
    rereadParTable
    info "writing data"
    dd if=$tchunk of=${dpar}$n bs=512 conv=noerror,sync
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
    # chunk size: 256 MiB
    local chunk=$(( 256 * 1024 * 2 ))
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
#echo "#####  calculating MD5 hash of partition"
#md5sum ${dpar}$n
    fi
}

### ext4

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
    processParRecreate $n $oldStart $oldSize $newStart $newSize
    info "formatting the partition in ext4 and trimming it"
    mke2fs -q -t ext4 -E discard $dev
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
            echo "REBOOT NEEDED: please reboot and retry the process to continue"
            exit 1
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
    checkTool e2fsck
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "will move the ext4 partition"
        warning "moving a big ext4 partition can take a very long time; it requires copying the complete partition, including its free space"
        checkTool dd
    fi
    if [ $(( newSize != oldSize )) -ne 0 ]; then
        info "will resize the ext4 partition"
        checkTool resize2fs
    fi
    if [ $(( newSize == oldSize )) -ne 0 ]; then
        info "will enlarge the ext4 file system if needed to fill its partition"
        checkTool resize2fs
    fi
    checkFs_ext4 $n $dev
}

processPar_ext4_keep_wet() {
    local n=$1
    local dev=$2
    local oldStart=$3
    local oldSize=$4
    local newStart=$5
    local newSize=$6
    local moveSize=$oldSize
    if [ $(( newSize < oldSize )) -ne 0 ]; then
        info "shrinking the ext4 file system"
        resize2fs -f $dev ${newSize}s
        info "shrinking the partition entry"
        processParRecreate $n $oldStart $oldSize $oldStart $newSize
        checkFs_ext4 $n $dev
        moveSize=$newSize
    fi
    if [ $(( newStart != oldStart )) -ne 0 ]; then
        info "moving the partition"
        # this should work but does not!
        #runParted move $n $newStart $(( $newStart + $moveSize - 1 ))
        #rereadParTable
        # so we manually dd data around
        processParMove $n $oldStart $newStart $moveSize
        checkFs_ext4 $n $dev
    fi
    if [ $(( newSize > oldSize )) -ne 0 ]; then
        info "enlarging the partition entry"
        processParRecreate $n $newStart $oldSize $newStart $newSize
        info "enlarging the ext4 file system"
        resize2fs -f $dev ${newSize}s
        checkFs_ext4 $n $dev
    fi
    if [ $(( newSize == oldSize )) -ne 0 ]; then
        info "enlarging the ext4 file system if needed to fill its partition"
        resize2fs -f $dev ${newSize}s
        checkFs_ext4 $n $dev
    fi
}

### vfat

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
    # the -w flag could be used here to bound memory use
    if ! dosfsck -pV $dev; then
        info "errors detected, retrying the file system check"
        if ! dosfsck -pV $dev; then
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
        runParted resize $n $newStart $(( $newStart + $newSize - 1 ))
        rereadParTable
        checkFs_vfat $@
    fi
}

### main

processPar() {
    echo "*****  processing $(parName $1)"
    eval processPar_$(parGet $1 fs)_$(parGet $1 content)_$mode $1 ${dpar}$1 $(parOldStart $1) $(parOldSize $1) $(parNewStart $1) $(parNewSize $1)
}

processParList() {
    local rest=${@:2}
    echo "-----  analyzing $(parName $1)"
    if [ -z "$rest" ]; then
        processPar $1
    else
        if [ $(( $(parNewEnd $1) > $(parOldStart $2) )) -ne 0 ]; then
            info "$(parName $1) will expand into disk area of $(parName $2)"
            info "deferring processing of $(parName $1)"
            processParList $rest
            processPar $1
        else
            processPar $1
            processParList $rest
        fi
    fi
}

checkDevice() {
    case ":$(getprop ro.product.device):$(getprop ro.build.product):" in
        *:galaxys2:*) ;;
        *:i9100:*) ;;
        *:GT-I9100:*) ;;
        *:GT-I9100M:*) ;;
        *:GT-I9100P:*) ;;
        *:GT-I9100T:*) ;;
        *:SC-02C:*) ;;
        *)
            fatal "this package is for '$deviceName' devices; this device is '$(getprop ro.product.device)'"
            ;;
    esac
}

checkTools() {
    checkTool parted
    checkTool sort
    checkTool blockdev
    checkTool sed
    checkTool awk
    checkTool mke2fs
    checkTool e2fsck
    checkTool dd
    checkTool resize2fs
    checkTool mkdosfs
    checkTool dosfsck
    checkTool readlink
    checkTool basename
    checkTool dirname
}

checkUnmount() {

    local hint
    if [ -f "$1" ]; then
        if [ "$(dirname $(readlink -f "$1"))" != "/tmp" ]; then
            info "copying package to /tmp"
            cp -f "$1" "/tmp/"
            hint="this package copied itself to /tmp; please run it again from there"
        else
            hint="please reboot TWRP and run this package again; run it immediately after boot up, do not enable USB mass storage; note that you might be told to run it yet again from /tmp; make sure your phone is not encrypted: encrypted phones are not supported"
        fi
    else
        hint="please use TWRP's file manager to copy this package to /tmp and run it again from there"
    fi

    info "unmounting all partitions"

    local dev
    for dev in $(grep -ow "^${dpar}[0-9]*" /proc/mounts | sort -u); do
        if ! umount $dev; then
            fatal "unable to unmount all partitions ($hint)"
        fi
    done

    # rereadParTable requires everything unmounted
    rereadParTable " ($hint)"

}

parsePackageNameParData() {
    local name="$1"
    local par="$2"
    parsedSize="$3"
    parsedContent="$4"
    parsedFs="$5"
    #info "defaults for '$par': size=$parsedSize, content=$parsedContent, fs=$parsedFs"
    local data="$(echo -n "$name" | sed -n "s/.*-${par}=\([^-=]*\)\(-.*\|\)\$/\1/p")"
    if [ -n "$data" ]; then
        if [ -n "$(echo -n "$data" | sed "s/^\([0-9.]*\|same\|min\|max\)\(+\(\|keep\|wipe\)\(+\(\|ext4\|vfat\)\)\?\)\?$//")" ]; then
            fatal "invalid partition configuration for '$par': $par=$data"
        fi
        local val
        val="$(echo -n "$data" | sed -n "s/^\([0-9.]*\|same\|min\|max\)\(+\(\|keep\|wipe\)\(+\(\|ext4\|vfat\)\)\?\)\?$/\1/p")"
        if [ -n "$val" ]; then parsedSize="$val"; fi
        val="$(echo -n "$data" | sed -n "s/^\([0-9.]*\|same\|min\|max\)\(+\(\|keep\|wipe\)\(+\(\|ext4\|vfat\)\)\?\)\?$/\3/p")"
        if [ -n "$val" ]; then parsedContent="$val"; fi
        val="$(echo -n "$data" | sed -n "s/^\([0-9.]*\|same\|min\|max\)\(+\(\|keep\|wipe\)\(+\(\|ext4\|vfat\)\)\?\)\?$/\5/p")"
        if [ -n "$val" ]; then parsedFs="$val"; fi
    fi
    #info "configuration for '$par': size=$parsedSize, content=$parsedContent, fs=$parsedFs"
    echo "$par: size=$parsedSize, content=$parsedContent, fs=$parsedFs"
}

parsePackageName() {

    local name="$1"

    info "valid package name: <prefix>[-system=<conf>][-data=<conf>][-sdcard=<conf>][-preload=<conf>]<suffix>"
    info "valid partition configuration: [<size-in-GiB>|same|min|max][+[keep|wipe][+[ext4|vfat]]]"
    info "partition configuration defaults: system|data|preload=same+keep+ext4 sdcard=same+keep+vfat"

    info "parsing package name"
    if [ -z "$name" ]; then
        fatal "unable to retrieve package name"
    fi
    name="$(basename "$name" .zip)"

    echo
    echo "-----  CONFIGURATION  -----"
    parsePackageNameParData "$name" system  same keep ext4
    system_size="$parsedSize"
    system_content="$parsedContent"
    system_fs="$parsedFs"
    parsePackageNameParData "$name" data    same keep ext4
    data_size="$parsedSize"
    data_content="$parsedContent"
    data_fs="$parsedFs"
    parsePackageNameParData "$name" sdcard  same keep vfat
    sdcard_size="$parsedSize"
    sdcard_content="$parsedContent"
    sdcard_fs="$parsedFs"
    parsePackageNameParData "$name" preload same keep ext4
    preload_size="$parsedSize"
    preload_content="$parsedContent"
    preload_fs="$parsedFs"
    echo

}

main() {
    echo " ####################################"
    echo "  Lanchon REPIT"
    echo "  A Data-Sparing Repartitioning Tool"
    echo "  Version: $version"
    echo "  Device: $deviceName"
    echo "  Copyright 2016, Lanchon (GPLv3)"
    echo " ####################################"
    echo
    echo "=====  PRELIMINARY CHECKS  ====="
    checkDevice
    checkTools
    parsePackageName "$1"
    checkUnmount "$1"
    echo
    echo "=====  PREPARATION  ====="
    setup
    echo
    echo "=====  DRY-RUN  ====="
    mode=dry
    processParList $(seq 9 12)
    echo
    echo "=====  EXECUTION  ====="
    mode=wet
    processParList $(seq 9 12)
    info "flushing buffers"
    sync
    blockdev --flushbufs $ddev
    sleep 3
    echo
    echo "=====  SUCCESS  ====="
    #echo
}

configureStockLayout() {

    # Stock partition layout for i9100

    system_size=0.5
    data_size=2
    #sdcard_size=11.5078
    sdcard_size=max
    preload_size=0.5

    #system_fs=ext4
    #data_fs=ext4
    #sdcard_fs=vfat
    #preload_fs=ext4

}

configureKeepData() {
    system_content=keep
    data_content=keep
    sdcard_content=keep
    preload_content=keep
}

# <partition>_size: <fractional-size-in-GiB>|min|max|same
# <partition>_content: keep|wipe
# <partition>_fs: ext4|vfat

#configureStockLayout
#configureKeepData

main "$@"
