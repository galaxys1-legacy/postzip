#!/sbin/busybox sh
#
# Copyright (C) 2008 The Android Open-Source Project
# Copyright (C) 2011 by Teamhacksung
# Copyright (C) 2013 OmniROM Project
#
# Modified by Humberto Borba <humberos@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

# log everything to /tmp/postzip.log
exec >> /tmp/postzip.log 2>&1;

# check mounts
check_mount() {
    local MOUNT_POINT=$(/sbin/busybox readlink "${1}");
    if ! /sbin/busybox test -n "${MOUNT_POINT}" ; then
        # readlink does not work on older recoveries for some reason
        # doesn't matter since the path is already correct in that case
        echo "Using non-readlink mount point ${1}";
        MOUNT_POINT="${1}";
    fi
    if ! /sbin/busybox grep -q "${MOUNT_POINT}" /proc/mounts ; then
        /sbin/busybox mkdir -p "${MOUNT_POINT}";
        /sbin/busybox umount -l "${2}";
        if ! /sbin/busybox mount -t "${3}" "${2}" "${MOUNT_POINT}" ; then
            echo "Cannot mount ${1} (${MOUNT_POINT}).";
            exit 1;
        fi
    fi
}

copy_ramdisks() {
    # format the ramdisk partitions and copy the ramdisks to them
    /sbin/busybox umount -l /dev/block/mtdblock1
    /tmp/erase_image ramdisk
    check_mount /ramdisk /dev/block/mtdblock1 yaffs2
    /sbin/busybox cp /tmp/ramdisk.img /ramdisk/ramdisk.img

    /sbin/busybox umount -l /dev/block/mtdblock2
    /tmp/erase_image ramdisk-recovery
    check_mount /ramdisk-recovery /dev/block/mtdblock2 yaffs2
    /sbin/busybox cp /tmp/ramdisk-recovery.img /ramdisk-recovery/ramdisk-recovery.img
    /sbin/busybox sync

    # unmount the ramdisk partitions
    /sbin/busybox umount -l /dev/block/mtdblock1
    /sbin/busybox umount -l /dev/block/mtdblock2
}