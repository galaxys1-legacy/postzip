#!/bin/bash

set -e

UPDATE_ZIP="$1"

SOURCE_DIR=$(pwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUT_DIR="${SOURCE_DIR}/out/target/product/galaxysmtd/"


# tmp dir to do our stuff
TMPD="/tmp/postinstallzip"
mkdir -p "$TMPD"
cd "$TMPD"

ZIP_OUT_FILE="$TMPD/postinstallzip.zip"

if [[ "$2" = "oops" ]]; then
# We fucked up and pressed key accidentaly.
adb sideload "$ZIP_OUT_FILE"
exit 1
fi;

# If no updatezip path was given assume
# We just want to create the postinstallzip.zip
if [[ -f "$SOURCE_DIR/$UPDATE_ZIP" ]]; then
# Start the sideload 
adb sideload "$SOURCE_DIR/$UPDATE_ZIP"
fi;

# Extract the ramdisk
RDROOT="$TMPD/root"
SDROOT="$SCRIPT_DIR/root"
mkdir -p "$RDROOT"
rm -rf "$RDROOT/"*
cd "$RDROOT"
gunzip -c "$OUT_DIR/ramdisk.img" | cpio -iudm

# Patch the ramdisk.
cp -rf "$SDROOT/"* "$RDROOT/"
chmod 0755 "$RDROOT/init"
chmod 0755 "$RDROOT/sbin/magisk"

# Patch in magisk support
sed -i '/import \/init.usb.rc/a \
import \/init.magisk.rc' "$RDROOT/init.rc"

# We're on a tmpfs.. but just in case
sync

# Repack the ramdisk We're still in RDROOT
find . | cpio --create --format='newc' | gzip > ../ramdisk.img

# Assemble the zip
ZIPIM="$TMPD/zip_im"
mkdir -p "$ZIPIM"
rm -rf "$ZIPIM/*"
cp -rf "$SCRIPT_DIR/META-INF" "$ZIPIM/"
cp -f  "$TMPD/ramdisk.img" "$ZIPIM/"
cp -f  "$SCRIPT_DIR/ramdisk-recovery.img" "$ZIPIM/"
cp -rf "$SCRIPT_DIR/updater.sh" "$ZIPIM/"

# Prepare the zip
cd "$ZIPIM"
7z a "$ZIP_OUT_FILE" ./*

if [[ "$2" = "test" ]]; then
# We are testing dont prompt to flash
printf "Sucessfully built:  $ZIP_OUT_FILE \n"
exit 1
fi;

printf "DONT FUCKING REBOOT!! \n"
printf "Enter any key after starting sideload again."

read;

adb sideload "$ZIP_OUT_FILE"
