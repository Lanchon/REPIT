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

version="2016-04-22"

### logging

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

### helpers

printSizeMiB() {
    local size="$1"
    echo "$(( (size) / $MiB )) MiB"
}

checkTool() {
    #info "checking tool: $1"
    if [ -z "$(which "$1")" ]; then
        fatal "required tool '$1' missing (please use a recent version of TWRP to run this package)"
    fi
}

chooseTool() {
    #info "choosing tool: $*"
    local tool
    for tool in "$@"; do
        if [ -n "$(which "$tool")" ]; then
            echo "$tool"
            return
        fi
    done
    fatal "all tool alternatives missing: $* (please use a recent version of TWRP to run this package)"
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

detectBlockDeviceHeapRange() {
    info "determining usable sector range of block device"
    checkTool sgdisk
    local out="$(sgdisk "$ddev" --set-alignment 1 --print)"
    deviceHeapStart=$(echo "$out" | sed -n "s/^First usable sector is[ ]*\([0-9]*\)[, ]*last usable sector is[ ]*\([0-9]*\)[ ]*$/\1/p")
    deviceHeapEnd=$(echo "$out" | sed -n "s/^First usable sector is[ ]*\([0-9]*\)[, ]*last usable sector is[ ]*\([0-9]*\)[ ]*$/\2/p")
    if [ -z "$deviceHeapStart" ] || [ -z "$deviceHeapEnd" ]; then
        warning "unable to parse sgdisk output (dump of output follows)"
        >&2 echo
        >&2 echo "$out"
        >&2 echo
        fatal "unable to determine usable sector range of block device"
    fi
    deviceHeapEnd=$(( deviceHeapEnd + 1 ))
}

alignDown() {
    echo $(( ($1) / heapAlignment * heapAlignment ))
}

alignUp() {
    echo $(( (($1) + (heapAlignment - 1)) / heapAlignment * heapAlignment ))
}

### data store

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

parFooterSize() {
    cat ${tpar}$1/footerSize
}

parNewSizeMinusFooter() {
    echo $(( $(parNewSize $1) - $(parFooterSize $1) ))
}

parNewSizeAligned() {
    cat ${tpar}$1/sizeAligned
}

parOldEnd() {
    echo $(( $(parOldStart $1) + $(parOldSize $1) ))
}

parNewEnd() {
    echo $(( $(parNewStart $1) + $(parNewSize $1) ))
}

parNewEndAligned() {
    echo $(( $(parNewStart $1) + $(parNewSizeAligned $1) ))
}

parGet() {
    cat ${tpar}$1/$2
}

parSet() {
    echo -n "$3" >${tpar}$1/$2
}

parName() {
    echo -n "partition #$1 '$(parGet $1 fname)' ($(parGet $1 pname))"
}

### initialization

detectSideload() {

    local packageName="$1"

    # /tmp/update.zip: old sideload protocol
    # /sideload/package.zip: current sideload-host protocol
    if [ "$1" == "/tmp/update.zip" ] || [ "$1" == "/sideload/package.zip" ]; then
        fatal "adb sideload is not directly supported: it hides the package filename and thus filename-based configuration does not work "\
"(please adb push the package to '/tmp' and run it from there; or adb sideload it after adding a 'flashize/settings' file to the package containing the desired package filename override)"
    fi

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

    checkTools_fs_ext4
    checkTools_fs_vfat
    checkTools_fs_f2fs
    checkTools_fs_swap
    checkTools_fs_raw

}

initPartitionConf() {

    local n=$1
    local size=$2
    local content=$3
    local fs=$4

    $(parSet $n parsedSize $size)
    $(parSet $n parsedContent $content)
    $(parSet $n parsedFs $fs)

}

initPartition() {

    local n=$1
    local pname=$2
    local fname=$3
    local conf=$4
    local footerSize=$5

    mkdir -p ${tpar}$n

    $(parSet $n pname $pname)
    $(parSet $n fname $fname)

    initPartitionConf $n $conf

    $(parSet $n footerSize $footerSize)

    initedPartitions="$initedPartitions $n"

}

initPartitions() {

    rm -rf $tdir

    initedPartitions=""
    device_initPartitions

}

parsePartitionConfiguration() {

    local n=$1
    local packageName="$2"

    local parName=$(parGet $n fname)
    local conf="$(echo -n "$packageName" | sed -n "s/.*-${parName}=\([^-=]*\)\(-.*\|\)\$/\1/p")"

    if [ -n "$conf" ]; then

        local regex="^\([0-9.]*\|same\|min\|max\)\(+\(\|keep\|wipe\)\(+\(\|ext4\|vfat\|f2fs\|swap\|raw\)\)\?\)\?$"

        if [ -n "$(echo -n "$conf" | sed "s/$regex//")" ]; then
            fatal "invalid partition configuration for '$parName': $parName=$conf"
        fi

        local val
        val="$(echo -n "$conf" | sed -n "s/$regex/\1/p")"
        if [ -n "$val" ]; then $(parSet $n parsedSize "$val"); fi
        val="$(echo -n "$conf" | sed -n "s/$regex/\3/p")"
        if [ -n "$val" ]; then $(parSet $n parsedContent "$val"); fi
        val="$(echo -n "$conf" | sed -n "s/$regex/\5/p")"
        if [ -n "$val" ]; then $(parSet $n parsedFs "$val"); fi

    fi

}

parsePackageName() {

    local packageName="$1"

    local parNames=""
    local n
    for n in $configurablePartitions; do
        if [ -n "$parNames" ]; then
            parNames="$parNames|"
        fi
        parNames="$parNames$(parGet $n fname)"
    done
    info "valid package names: <prefix>[-($parNames)=<conf>]...<suffix>"
    info "valid partition <conf> values: [<size-in-GiB>|same|min|max][+[keep|wipe][+[ext4|vfat|f2fs|swap|raw]]]"

    echo
    echo "-----  DEFAULTS  -----"
    for n in $configurablePartitions; do
        #echo "-$(parGet $n fname)=$(parGet $n parsedSize)+$(parGet $n parsedContent)+$(parGet $n parsedFs)"
        echo "$(parGet $n fname) = size:$(parGet $n parsedSize) + content:$(parGet $n parsedContent) + fs:$(parGet $n parsedFs)"
    done
    echo

    info "parsing package name"
    if [ -z "$packageName" ]; then
        fatal "unable to retrieve package name"
    fi
    packageName="$(basename "$packageName" .zip)"
    for n in $configurablePartitions; do
        parsePartitionConfiguration $n $packageName
    done

    echo
    echo "-----  CONFIGURATION  -----"
    for n in $initedPartitions; do
        #echo "-$(parGet $n fname)=$(parGet $n parsedSize)+$(parGet $n parsedContent)+$(parGet $n parsedFs)"
        echo "$(parGet $n fname) = size:$(parGet $n parsedSize) + content:$(parGet $n parsedContent) + fs:$(parGet $n parsedFs)"
    done
    echo

}

disableSwap() {
    #info "checking tool: swapoff"
    if [ -n "$(which swapoff)" ]; then
        info "disabling swap"
        swapoff -a
    fi
}

checkUnmount() {

    local packageName="$1"

    if [ ! -e $ddev ] || [ ! -e $sdev ]; then
        fatal "block device not found"
    fi

    local hint
    if [ -f "$packageName" ]; then
        local resolvedPackageName
        resolvedPackageName="$(readlink -f "$packageName")"
        if [ -z "$resolvedPackageName" ]; then
            resolvedPackageName="$packageName"
        fi
        if [ "$(dirname "$resolvedPackageName")" != "/tmp" ]; then
            info "copying package to '/tmp'"
            cp -f "$packageName" "/tmp/"
            hint="this package copied itself to '/tmp'; please run it again from there"
        else
            hint=\
"please disable MTP in TWRP's 'Mount' menu (or disconnect from PC), reboot TWRP and run this package again; "\
"run it immediately after boot up, do not enable USB mass storage; "\
"note that you might be told to run it yet again from '/tmp'; "\
"make sure your phone is not encrypted: encrypted phones are not supported"
        fi
    else
        hint="please use TWRP's file manager to copy this package to '/tmp' and run it again from there"
    fi

    info "unmounting all partitions"

    local dev
    for dev in $(grep -ow "^$unmountPattern" /proc/mounts | sort -u); do
        if ! umount $dev; then
            fatal "unable to unmount all partitions ($hint)"
        fi
    done

    # rereadParTable requires everything unmounted
    rereadParTable " ($hint)"

}

init() {

    local packageName="$1"

    detectSideload "$packageName"

    tdir=/tmp/lanchon-repit
    tchunk=$tdir/chunk.tmp
    tpar=$tdir/partition-info/p

    device_init
    
    MiB=$((        1024 * 1024 / sectorSize ))      # 1 MiB in sectors
    GiB=$(( 1024 * 1024 * 1024 / sectorSize ))      # 1 GiB in sectors
    
    checkTools
    initPartitions
    parsePackageName "$packageName"
    disableSwap
    checkUnmount "$packageName"

}

### setup

setup() {

    checkTool parted
    checkTool sort
    checkTool blockdev
    checkTool awk

    #info "unmounting all partitions"
    #...
    #rereadParTable

    heapSizeUnit=$GiB
    heapMinSize=$(( 8 * MiB ))

    device_setup

    if [ -z "$heapSizeGranularity" ]; then
        heapSizeGranularity=$heapAlignment
    fi

    info "checking existing partitions"

    local n
    for n in $(seq 1 $partitionCount); do
        if [ ! -e ${spar}$n ]; then
            fatal "partition #$n: not found"
        fi
        if [ $(( $(parOldStart $n) < 0 )) -ne 0 ]; then
            fatal "partition #$n: invalid start"
        fi
        if [ $(( $(parOldSize $n) <= 0 )) -ne 0 ]; then
            fatal "partition #$n: invalid size"
        fi
    done
    
    for n in $(seq $(( partitionCount + 1 )) $(( partitionCount + 100 )) ); do
        if [ -e ${spar}$n ]; then
            fatal "partition #$n: unexpected"
        fi
    done

}

setupHeapExisting() {

    info "checking existing partition layout"

    # TODO: verify that no partitions that are not members of the heap step into the heap area.
    # TODO: maybe verify that all partitions that are members of the heap are fully contained in the heap area.

    local nPrev=""
    local gap
    local n
    for n in $heapPartitions; do
        info "current size: $(parName $n): $(printSizeMiB $(parOldSize $n))"
        if [ -z "$nPrev" ]; then
            gap=$(( $(parOldStart $n) - heapStart ))
            if [ $(( gap < 0 )) -ne 0 ]; then
                warning "$(parName $n) starts $(printSizeMiB $(( -(gap) )) ) before the start of heap '$heapName'"
            fi
            gap=$(( $(parOldStart $n) - heapStartAligned ))
            if [ $(( gap > 0 )) -ne 0 ]; then
                warning "$(parName $n) starts $(printSizeMiB $gap) after the aligned start of heap '$heapName'"
            fi
        else
            gap=$(( $(parOldStart $n) - $(parOldEnd $nPrev) ))
            if [ $(( gap < 0 )) -ne 0 ]; then
                fatal "layout reversal between $(parName $nPrev) and $(parName $n) in heap '$heapName'"
            fi
            gap=$(( $(parOldStart $n) - $(alignUp $(parOldEnd $nPrev)) ))
            if [ $(( gap > 0 )) -ne 0 ]; then
                warning "$(parName $n) starts $(printSizeMiB $gap) after the aligned end of $(parName $nPrev)"
            fi
        fi
        nPrev=$n
    done
    gap=$(( heapEnd - $(parOldEnd $nPrev) ))
    if [ $(( gap < 0 )) -ne 0 ]; then
        warning "$(parName $nPrev) ends $(printSizeMiB $(( -(gap) )) ) after the end of heap '$heapName'"
    fi
    if [ $(( gap >= heapAlignment )) -ne 0 ]; then
        warning "$(parName $nPrev) ends $(printSizeMiB $gap) before the end of heap '$heapName'"
    fi

}

setupHeapPartition() {

    local n=$1

    local size="$(parGet $n parsedSize)"
    local content="$(parGet $n parsedContent)"
    local fs="$(parGet $n parsedFs)"

    if [ -z "$size" ]; then
        fatal "$(parName $n): undefined new size"
    fi
    if [ -z "$content" ]; then
        fatal "$(parName $n): undefined content policy"
    fi
    if [ -z "$fs" ]; then
        fatal "$(parName $n): undefined file system type"
    fi

    case "$size" in
        same)
            size=$(parOldSize $n)
            ;;
        min)
            size=$heapMinSize
            ;;
        max)
            size=0
            ;;
        *)
            local unitFactor=$(( heapSizeUnit / heapSizeGranularity ))
            size=$(awk "BEGIN {print int(($size) * $unitFactor + 0.5)}")
            size=$(( size * heapSizeGranularity ))
            if [ $(( size < heapSizeGranularity )) -ne 0 ]; then
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
        f2fs)
            ;;
        swap)
            ;;
        raw)
            ;;
        *)
            fatal "$(parName $n): invalid file system type"
            ;;
    esac    

    $(parSet $n size $size)
    $(parSet $n content $content)
    $(parSet $n fs $fs)

    $(parSet $n sizeAligned $(alignUp $size))

}

setupHeapNew() {

    info "checking new partition layout"

    local n
    for n in $heapPartitions; do
        setupHeapPartition $n
    done

    local sizeAligned=$(( heapEndAligned - heapStartAligned ))

    # correct $sizeAligned in case the size of last partition and the end of heap are both unaligned,
    # and their combination would lead to an unused area at heap end the size of $heapAlignment or larger.
    local lastPar=$n
    local lastParEnd=$(( heapEndAligned - $(parNewSizeAligned $lastPar) + $(parNewSize $lastPar) ))
    if [ $(( heapEnd - lastParEnd >= heapAlignment )) -ne 0 ]; then
        sizeAligned=$(( sizeAligned + heapAlignment ))
    fi

    for n in $heapPartitions; do
        sizeAligned=$(( sizeAligned - $(parNewSizeAligned $n) ))
    done

    local maxPar
    for n in $heapPartitions; do
        if [ $(( $(parNewSize $n) == 0 )) -ne 0 ]; then
            if [ -n "$maxPar" ]; then
                fatal "more than one partition in heap '$heapName' has its size set to 'max'"
            fi
            maxPar=$n
            local size=$(( sizeAligned / heapSizeGranularity * heapSizeGranularity ))
            if [ $(( size < heapSizeGranularity )) -ne 0 ]; then
                fatal "the new partition layout of heap '$heapName' requires more space than available"
            fi
            $(parSet $n size $size)
            $(parSet $n sizeAligned $sizeAligned)
        fi
        info "new size: $(parName $n): $(printSizeMiB $(parNewSize $n))"
    done

    local nextStart=$heapStartAligned
    for n in $heapPartitions; do
        $(parSet $n start $nextStart)
        nextStart=$(parNewEndAligned $n)
    done

    gap=$(( heapEnd - $(parNewEnd $lastPar) ))
    if [ $(( gap < 0 )) -ne 0 ]; then
        fatal "the new partition layout of heap '$heapName' requires more space than available"
    fi
    if [ $(( gap >= heapAlignment )) -ne 0 ]; then
        warning "there will be $(printSizeMiB $gap) of unused space at the end of heap '$heapName'"
    fi

}

setupHeap() {

    setupHeapExisting
    setupHeapNew

}

forEachHeap() {

    for heapName in $allHeaps; do

        echo "#####  processing heap '$heapName'"

        device_setupHeap_$heapName

        heapStartAligned=$(alignUp $heapStart)
        heapEndAligned=$(alignDown $heapEnd)

        "$@"

    done

}

### execution

processPar() {

    local n=$1

    echo "*****  processing $(parName $n)"

    eval processPar_$(parGet $n fs)_$(parGet $n content)_$processMode $n ${dpar}$n $(parOldStart $n) $(parOldSize $n) $(parNewStart $n) $(parNewSize $n)

}

processParList() {

    local first=$1
    local rest=${@:2}

    echo "-----  analyzing $(parName $first)"

    if [ -z "$rest" ]; then

        processPar $first

    else

        local second=$2

        if [ $(( $(parNewEnd $first) > $(parOldStart $second) )) -ne 0 ]; then
            info "$(parName $first) will expand into storage area currently used by $(parName $second)"
            info "deferring processing of $(parName $first) until required space is freed"
            processParList $rest
            processPar $first
        else
            processPar $first
            processParList $rest
        fi

    fi

}

processHeap() {

    processMode=$1

    processParList $heapPartitions

}

flushBuffers() {

    info "flushing buffers"

    sync
    blockdev --flushbufs $ddev
    sleep 3

}

### main

main() {

    local packageName="$1"

    echo " ####################################"
    echo "  Lanchon REPIT"
    echo "  A Data-Sparing Repartitioning Tool"
    echo "  Version: $version"
    echo "  Device: $deviceName"
    echo "  Copyright 2016, Lanchon (GPLv3)"
    echo " ####################################"
    echo

    echo "=====  PRELIMINARY CHECKS  ====="
    if [ -f "/tmp/repit-settings" ]; then
        packageName="$(cat "/tmp/repit-settings")"
        info "overriding configuration via '/tmp/repit-settings' to '$packageName'"
    elif [ -n "$FLASHIZE_ENV_VERSION" ] && [ -f "/tmp/flashize/repit-settings" ]; then
        packageName="$(cat "/tmp/flashize/repit-settings")"
        info "overriding configuration via 'flashize/repit-settings' to '$packageName'"
    fi
    init "$packageName"
    echo

    echo "=====  PREPARATION  ====="
    setup
    forEachHeap setupHeap
    echo

    echo "=====  DRY-RUN  ====="
    forEachHeap processHeap dry
    echo

    echo "=====  EXECUTION  ====="
    forEachHeap processHeap wet
    flushBuffers
    echo

    echo "=====  SUCCESS  ====="
    #echo

}
