#!/bin/bash

# Script for the realization of the SDcard image and its configuration
#set -e

# Included files
DIR_MKUDOOBUNTU=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
REQUIRED_HOST_PKG=( qemu-user-static qemu-user debootstrap )
cd $DIR_MKUDOOBUNTU
source "configure/udoo_neo.sh"
source "include/imager.sh"
source "include/packages.sh"
source "include/set_user_and_root.sh"
source "include/utils/prints.sh"
source "include/utils/utils.sh"
cd -
################################################################################

function check_env() {
    for i in ${REQUIRED_HOST_PKG[@]}
    do
        local PKGLIST=$(dpkg -l)
        if ! grep -q $i <<< $PKGLIST
        then
            apt install -y $i
        fi
    done
}

PRINTS_DEBUG=1
PRINTS_VERBOSE=1

export MNTDIR=mnt
export IMGSIZE=3
# The first stage is the function that do the initial operation such as:
# creating partitions, upload the bootloader, ...
# Many of its operation are taken from ../include/imager.sh
function bootstrap() {
    # Read arguments
    local OUTPUT=$1
    local LOOP=$2
    export LANG=C
    export LC_ALL=C
    export LANGUAGE=C
    export DEBIAN_PRIORITY=critical
    export DEBIAN_FRONTEND=noninteractive
    export DEBCONF_NONINTERACTIVE_SEEN=true

    echo_i "Starting setup"

    echo_i "Starting debootstrap ..."
    qemu-debootstrap --arch=armhf --verbose focal "$MNTDIR" 2>&1 > out.log &
    local process_pid=$!
    progress_bar $process_pid "first stage"
    cp /usr/bin/qemu-arm-static "${MNTDIR}/usr/bin"
    # Copy the kernel - from include/imager.sh
    mkdir -p "${MNTDIR}/boot/"
    write_kernel $MNTDIR
    echo_ok "Bootstrap: DONE"
}

# This function configure the system: adding the default user, set the root
# password, install the packages...
function configuration() {
    echo_i "Starting configuration..."
    # Edit the hostname file
    chroot "${MNTDIR}/" /bin/bash -c "echo \"$HOSTNAME\" > /etc/hostname"

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
    
    #Install firmwares
    cp "source/firmware/"* "./${MNTDIR}/lib/firmware/ti-connectivity/"
    echo_i "Adding resizefs"
    install -m 755 patches/firstrun  "./${MNTDIR}/etc/init.d"
    chroot "${MNTDIR}/" /bin/bash -c "update-rc.d firstrun defaults > /dev/null 2>&1"
    cp patches/g_multi_setup.sh "./${MNTDIR}/etc/rc.local"
    chmod +x "./${MNTDIR}/etc/rc.local"

    echo_i "Configuring Network ..."
    cp patches/network_interface "./${MNTDIR}/etc/netplan/01-network-manager-all.yaml"
    cp patches/resolv.conf "${MNTDIR}/etc/resolv.conf"
    # Setup the user and root - from include/set_user_and_root.sh
    set_root
    set_user

    echo_ok "Configuration complete!"
}

function create_image(){
    # Create the empty image file - 4GB
    echo_i "Creating the image file $OUTPUT..."
    dd if=/dev/zero of=$OUTPUT bs=1 count=0 seek="${IMGSIZE}G" 2>&1 > /dev/null
    echo_ok "Image created!"
    # Associate loop-device with .img file
    losetup $LOOP $OUTPUT || echo_red "Cannot set $LOOP"
    # Create the partitions - from include/imager.sh
    create_partitions $OUTPUT $LOOP
    # Copy the bootloader - from include/imager.sh
    write_bootloader $OUTPUT $LOOP
    echo_e "$LOOP $MNTDIR"
    mount "${LOOP}p1" $MNTDIR
    read -p "Press any key to resume ..."
}

function clean() {
    # Read arguments
    local LOOP=$1

    if [ -d $MNTDIR ]
    then
        umount  $MNTDIR
        rm -rf $MNTDIR
    fi
    losetup -d "$LOOP"
    sync

    echo_ok "Cleaned successfully"
}

################################################################################
function main() {
    #checkroot
    # Configuration
    local OUTPUT="udoobuntu-udoo_neo-20.04_$(date +%Y%m%d-%H%M).img"
    local LOOP=$(losetup -f)

    echo_i "Check dependencies..."
    check_env
    check_dependencies "debootstrap"
    check_dependencies "qemu-arm-static"
    create_image

    trap "clean $LOOP" INT TERM KILL

    echo_i "Starting build..."
    bootstrap $OUTPUT $LOOP
    configuration

    echo_ok "Build complete!"
}

main $@
