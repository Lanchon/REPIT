#!/bin/bash

set -e

versionLong="$(sed -n "s/^version=\"\(.*\)\"$/\1/p" repit.sh)"
versionShort="$(echo "$versionLong" | sed "s/-//g")"

echo "Version: $versionLong"

unsigned=lanchon-repit-unsigned.zip
signed=lanchon-repit-$versionShort-system=1.0-data=same-sdcard=max-preload=min+wipe-i9100.zip

mkdir -p build
rm -f build/lanchon-repit-*.zip

flashize repit.sh build/$unsigned
signapk -w key/testkey.x509.pem key/testkey.pk8 build/$unsigned build/$signed

rm build/$unsigned
