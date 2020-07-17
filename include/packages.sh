#!/bin/bash

# Script fot update and install the packages and programs

# Included script

LOG_FILE_PATH="log/out.log"
DIR_PACKAGES=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR_PACKAGES/utils/prints.sh"
################################################################################
ROOTFS_CMD_APT_INSTALL="apt-get install -qy -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
EXPORTS="export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
export LANGUAGE=C
export LANG=C
export DEBIAN_PRIORITY=critical
export DEBCONF_NONINTERACTIVE_SEEN=true"

function add_source_list() {
    echo_i "Adding source list"
    install -m 644 $DIR_PACKAGES/../configure/sources.list "$MNTDIR/etc/apt/sources.list"
}


function set_locales(){
    echo_i "Setup Locale"
    chroot "${MNTDIR}/" /bin/bash <<EOF
locale-gen en_US.UTF-8
dpkg-reconfigure --frontend noninteractive locales
update-locale LANG=en_US.UTF-8
EOF
}

function install_packages() {
    # Update
    echo_i "Installing update..."
    chroot "${MNTDIR}/" /bin/bash -c "apt-get update -y"
    chroot "${MNTDIR}/" /bin/bash -c "apt-get upgrade -y"

    # # Packages list
    local base_packages="openssh-server ifupdown haveged policykit-1 curl iw network-manager ntp unzip usbutils wireless-tools wget wpasupplicant sysfsutils git i2c-tools python3-pip manpages wireless-regdb net-tools ca-certificates gnupg-agent linux-firmware vim bluez bluez-tools"

    echo_i "Installing basic packages..."
    chroot "${MNTDIR}/" /bin/bash <<EOF
${EXPORTS}
${ROOTFS_CMD_APT_INSTALL} $base_packages
EOF
}
