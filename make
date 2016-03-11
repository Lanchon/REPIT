#!/bin/bash

set -e

makeZip() {

    local device="$1"

    echo "Device: $device"

    ./make-script "$device"
    script="build/lanchon-repit-$device.sh"

    makeFilenameConfig="$(sed -n "s/^device_makeFilenameConfig=\"\(.*\)\"$/\1/p" "$script")"
    if [ -z "$makeFilenameConfig" ]; then
        >&2 echo "value not found: 'makeFilenameConfig'"
        exit 1
    fi

    unsigned="build/lanchon-repit-unsigned-$device.zip"
    signed="build/lanchon-repit-$versionShort-$makeFilenameConfig-$device.zip"

    flashize "$script" "$unsigned"
    signapk -w key/testkey.x509.pem key/testkey.pk8 "$unsigned" "$signed"

    #rm "$script"
    rm "$unsigned"

}

make() {

    local device="$1"

    versionLong="$(sed -n "s/^version=\"\(.*\)\"$/\1/p" repit.sh)"
    if [ -z "$versionLong" ]; then
        >&2 echo "value not found: 'version'"
        exit 1
    fi

    versionShort="$(echo "$versionLong" | sed "s/-//g")"

    echo "Version: $versionLong"

    mkdir -p build
    if [ -z "$device" ]; then
        rm -f build/lanchon-repit*
        for f in device/*.sh; do
            makeZip "$(basename "$f" .sh)"
        done
    else
        rm -f build/lanchon-repit*-"$device".*
        makeZip "$device"
    fi

}

make "$1"
