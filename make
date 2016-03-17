#!/bin/bash

set -e

makeZip() {

    local device="$1"

    echo "device: $device"

    ./make-script "$device"
    script="build/lanchon-repit-$device.sh"

    makeFilenameConfig="$(sed -n "s/^device_makeFilenameConfig=\"\(.*\)\"$/\1/p" "$script")"
    if [ -z "$makeFilenameConfig" ]; then
        >&2 echo "error: value not found: 'makeFilenameConfig'"
        exit 1
    fi

    unsignedZip="build/lanchon-repit-unsigned-$device.zip"
    signedZip="build/lanchon-repit-$versionShort-$makeFilenameConfig-$device.zip"

    flashize "$script" "$unsignedZip"
    signapk -w key/testkey.x509.pem key/testkey.pk8 "$unsignedZip" "$signedZip"

    #rm "$script"
    rm "$unsignedZip"

}

make() {

    local device="$1"

    versionLong="$(sed -n "s/^version=\"\(.*\)\"$/\1/p" repit.sh)"
    if [ -z "$versionLong" ]; then
        >&2 echo "error: value not found: 'version'"
        exit 1
    fi
    versionShort="$(echo "$versionLong" | sed "s/-//g")"

    echo "version: $versionLong"

    mkdir -p build
    if [ -z "$device" ]; then

        rm -f build/lanchon-repit*
        local f
        for f in $(find device -name "*.sh"); do
            local d="$(basename "$f" .sh)"
            if [ "$d" != "common" ]; then
                makeZip "$d"
            fi
        done

    else

        rm -f build/lanchon-repit*-"$device".*
        makeZip "$device"

    fi

}

make "$@"
