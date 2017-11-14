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
ZIPIM="$TMPD/zip_im"

prepare_ramdisk() {
# Extract the ramdisk
RDROOT="$TMPD/root"
SDROOT="$SCRIPT_DIR/root"
mkdir -p "$RDROOT"
rm -rf "$RDROOT/"*
cd "$RDROOT"
gunzip -c "$OUT_DIR/ramdisk.img" | cpio -iudm

# Patch the ramdisk.
cp -rf "$SDROOT/"* "$RDROOT/"
mkdir "$RDROOT/acct"
chmod 0755 "$RDROOT/init"
chmod 0755 "$RDROOT/sbin/magisk"

# Patch in magisk support
sed -i '/import \/init.usb.rc/a \
import \/init.magisk.rc' "$RDROOT/init.rc"
# Repack the ramdisk We're still in RDROOT
find . | cpio --create --format='newc' | gzip > ../ramdisk.img
}


assemble_postzip() {
# Assemble the zip
mkdir -p "$ZIPIM"
rm -rf "$ZIPIM/*"
cp -rf "$SCRIPT_DIR/META-INF" "$ZIPIM/"
cp -f  "$TMPD/ramdisk.img" "$ZIPIM/"
cp -f  "$SCRIPT_DIR/ramdisk-recovery.img" "$ZIPIM/"
cp -rf "$SCRIPT_DIR/updater.sh" "$ZIPIM/"
}

create_postzip() {
	cd "$ZIPIM"
	7z a "$ZIP_OUT_FILE" ./*
}


if [[ "$2" = "test" ]]; then
	# We are testing dont prompt to flash
	prepare_ramdisk
	printf "Sucessfully built: ramdisk.img \n"
	exit 1
fi;

if [[ "$2" = "try" ]]; then
	# We are trying new stuffs so build postinstallzip
	prepare_ramdisk
	assemble_postzip
	create_postzip
	printf "Sucessfully built: \n"
	exit 1
fi;

if [[ -f "$SOURCE_DIR/$UPDATE_ZIP" ]]; then
	prepare_ramdisk
	assemble_postzip
	# We want to patch the update zip
	cp "$SOURCE_DIR/$UPDATE_ZIP" "$ZIPIM/"
	FINAL_ZIP=$(basename "$UPDATE_ZIP")
	# We need to be in currentdir
	cd "$ZIPIM"
	zip -u "$ZIPIM/$FINAL_ZIP" ramdisk.img
	zip -u "$ZIPIM/$FINAL_ZIP" ramdisk-recovery.img
	# Update boot.img if there is one
	if [[ -f "$ZIPIM/boot.img" ]]; then
		zip -u "$ZIPIM/$FINAL_ZIP" boot.img
	fi;
fi;

# Sideload only if we were prompted to:
if [[ "$2" = "flash" ]]; then
	adb sideload 	 "$ZIPIM/$FINAL_ZIP"
fi;

