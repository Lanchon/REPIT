#!/bin/bash

set -e

makeZip() {

    local device="$1"

    echo "device: $device"

    script="build/lanchon-repit-$device.sh"
    ./make-script "$device" "$script"

    makeFlashizeEnv="$(sed -n "s/^device_makeFlashizeEnv=\"\(.*\)\"$/\1/p" "$script")"
    if [ -z "$makeFlashizeEnv" ]; then
        >&2 echo "error: value not found: 'device_makeFlashizeEnv'"
        exit 1
    fi

    makeFilenameConfig="$(sed -n "s/^device_makeFilenameConfig=\"\(.*\)\"$/\1/p" "$script")"
    if [ -z "$makeFilenameConfig" ]; then
        >&2 echo "error: value not found: 'device_makeFilenameConfig'"
        exit 1
    fi

    unsignedZip="build/lanchon-repit-unsigned-$device.zip"
    signedZip="build/lanchon-repit-$versionShort-$makeFilenameConfig-$device.zip"

    flashize-env "$script" "$makeFlashizeEnv" "$unsignedZip" /tmp/lanchon-repit.log
    signapk -w key/testkey.x509.pem key/testkey.pk8 "$unsignedZip" "$signedZip"

    #rm "$script"
    rm "$unsignedZip"

}

makeOne() {

    local device="$1"

    rm -f build/lanchon-repit*-"$device".*
    makeZip "$device"

}

makeAll() {

    rm -f build/lanchon-repit*
    local f
    for file in $(find device -type f -not -path '*/\.*' -name "*.sh"); do
        local device="$(basename "$file" .sh)"
        if [ "$device" != "common" ]; then
            makeZip "$device"
        fi
    done

}

make() {

    versionLong="$(sed -n "s/^version=\"\(.*\)\"$/\1/p" repit.sh)"
    if [ -z "$versionLong" ]; then
        >&2 echo "error: value not found: 'version'"
        exit 1
    fi
    versionShort="$(echo "$versionLong" | sed "s/-//g")"

    echo "version: $versionLong"

    mkdir -p build
    if [ $# -eq 0 ]; then
        makeAll
    else
        while [ $# -ne 0 ]; do
            makeOne "$1"
            shift
        done
    fi

}

make "$@"
