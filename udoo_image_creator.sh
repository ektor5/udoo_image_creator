#!/bin/bash

# Script for the realization of the SDcard image and its configuration
set -ex

# Included files
DIR_MKUDOOBUNTU=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
REQUIRED_HOST_PKG=( qemu-user-static qemu-user qemu-debootstrap )
source "$DIR_MKUDOOBUNTU/include/imager.sh"
source "$DIR_MKUDOOBUNTU/include/utils/color.sh"
source "$DIR_MKUDOOBUNTU/include/set_user_and_root.sh"
source "$DIR_MKUDOOBUNTU/include/packages.sh"
source "$DIR_MKUDOOBUNTU/include/utils/color.sh"
source "$DIR_MKUDOOBUNTU/include/utils/utils.sh"
source "$DIR_MKUDOOBUNTU/configure/udoo_neo.sh"
################################################################################

function check_env() {
    for i in ${REQUIRED_HOST_PKG[@]}
    do
        if ! dpkg -l $i >/dev/null
            apt install -y $i
        fi
    done
}

# The first stage is the function that do the initial operation such as:
# creating partitions, upload the bootloader, ...
# Many of its operation are taken from ../include/imager.sh
function first_stage() {
    # Read arguments
    local OUTPUT=$1
    local LOOP=$2

    echo_yellow "Starting setup"

    # Create the empty image file - 4GB
    echo "Creating the image file $OUTPUT..."
    dd if=/dev/zero of=$OUTPUT bs=1 count=0 seek=3G
    echo_green "Image created!"
    # Associate loop-device with .img file
    losetup $LOOP $OUTPUT || echo_red "Cannot set $LOOP"

    # Create the partitions - from include/imager.sh
    create_partitions $OUTPUT $LOOP
    # Copy the bootloader - from include/imager.sh
    write_bootloader $OUTPUT $LOOP

    # Mount udoobuntu18_04
    mkdir mnt 2> /dev/null
    mount "${LOOP}p1" mnt/
    # Copy the kernel - from include/imager.sh
    mkdir mnt/boot/
    write_kernel $OUTPUT $LOOP

    echo_green "Setup complete!"

    # Debootstrap - first_stage
    echo "Starting debootstrap - first stage..."
    debootstrap --foreign --arch=armhf --verbose bionic mnt/ 2>&1 > out.log &
    local process_pid=$!
    progress_bar $process_pid "first stage"
    #tar -C mnt/ -xf ubuntu-base-18.04.3-base-armhf.tar
    echo_green "debootstrap - first_stage: Done!"

}


# The second stage is the function that give the final configuration to
# the image file. An important operation is the debootstrap operaion executed
# in chroot.
function second_stage() {
    echo_yellow "Starting second-stage"

    # Copy the qemu file
    cp /usr/bin/qemu-arm-static mnt/usr/bin

    # Change root and run the second stage
    chroot mnt/ /bin/bash -c "/debootstrap/debootstrap --second-stage" 2>&1 >> out.log &
    local process_pid=$!
    progress_bar $process_pid "second stage"

    echo_green "Debootstrap second-stage completed!"
}

# This function configure the system: adding the default user, set the root
# password, install the packages...
function configuration() {
    echo_yellow "Starting configuration..."
    # Edit the hostname file
    chroot mnt/ /bin/bash -c "echo \"$HOSTNAME\" > /etc/hostname"

    # Install packages - from include/packages.sh
    add_source_list >> out.log 2>&1 &
    local process_pid=$!
    progress_bar $process_pid "setup source list"
    set_locales >> out.log 2>&1 &
    process_pid=$!
    progress_bar $process_pid "setup locale"
    install_packages >> out.log 2>&1 &
    process_pid=$!
    progress_bar $process_pid "install packages"
    
    echo_yellow "Adding resizefs"
    install -m 755 patches/firstrun  "mnt/etc/init.d"
    chroot "mnt/" /bin/bash -c "update-rc.d firstrun defaults 2>&1 >/dev/null"
    cp patches/g_multi_setup.sh mnt/etc/rc.local
    chmod +x mnt/etc/rc.local



    # Setup the user and root - from include/set_user_and_root.sh
    set_root
    set_user

    echo_green "Configuration complete!"
}


function final_operations() {
    # Read arguments
    local LOOP=$1

    umount -lf mnt
    rm -rf mnt
    losetup -d "$LOOP"
    sync
}

################################################################################
function main() {
    # Configuration
    local OUTPUT="udoobuntu-udoo_neo-18.04_$(date +%Y%m%d-%H%M).img"
    local LOOP=$(losetup -f)

    echo_yellow "Starting build..."

    check_env
    first_stage $OUTPUT $LOOP
    second_stage $OUTPUT $LOOP
    configuration
    final_operations $LOOP

    echo_green "Build complete!"
}

main $@
