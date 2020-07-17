#!/bin/bash

# Script for the creation of the SDcard image

# Included script
DIR_IMAGER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR_IMAGER/utils/utils.sh"
source "$DIR_IMAGER/utils/prints.sh"
PRINTS_DEBUG=1
PRINTS_VERBOSE=1
################################################################################

function create_partitions() {
    # Read arguments
    local OUTPUT=$1
    local LOOP=$2

    # Configuration
    OFFSET="1"
    ROOTSTART=$(($OFFSET*2048))

    # Partitions name
    local LABELFS="udoobuntu20_04"

    # Create image partitions (spaces and filesystems)
    echo "Creating image partitions..."
    parted -s $LOOP -- mklabel msdos
    parted -s $LOOP -- mkpart primary ext4  $ROOTSTART"s" -1"s"
    partprobe $LOOP
    mkfs.ext4 -O '^64bit' -q $LOOP"p1" -L "$LABELFS"

    echo_ok "Partitions created in $OUTPUT!"
}

function write_bootloader() {
    # Read arguments
    local OUTPUT=$1
    local LOOP=$2

    echo "Writing U-Boot..."
    dd if="$DIR_IMAGER/../source/bootloader/SPL" of="$LOOP" bs=1k seek=1 2>&1 > /dev/null
    dd if="$DIR_IMAGER/../source/bootloader/u-boot.img" of="$LOOP" bs=1k seek=69 2>&1 > /dev/null
    echo_ok "Writing U-Boot: Done!"
}

function write_kernel() {
    # Read arguments
    local DIR=$1

    echo "Writing kernel and modules (version 4.14.78)"
    # Copy the image and the device tree (binary file)
    mkdir -p $DIR/boot/dtbs
    cp $DIR_IMAGER/../source/kernel/zImage $DIR/boot
    cp $DIR_IMAGER/../source/kernel/dtbs/*.dtb $DIR/boot/dtbs

    # Copy the modules
    mkdir -p $DIR/lib/modules
    cp -r $DIR_IMAGER/../source/kernel/modules/* $DIR/lib/modules

    echo_ok "Writing kernel and modules: Done!"
}
