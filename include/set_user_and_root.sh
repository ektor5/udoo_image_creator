#!/bin/bash

# Script for the setup of the default user

# Included script
DIR_SET_USER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "$DIR_SET_USER/utils/prints.sh"
################################################################################

function set_root() {
    echo_i Setting root...
    # Setup the root password
    chroot "${MNTDIR}/" /bin/bash -c "echo root:$ROOTPWD | chpasswd"
}

function set_user() {
    echo_i Setting user...
    # Setup the user and user password
    chroot "${MNTDIR}/" /bin/bash -c "useradd -U -m -G sudo,adm,dip,plugdev,dialout $USERNAMEPWD"
    chroot "${MNTDIR}/" /bin/bash -c "echo $USERNAMEPWD:$USERNAMEPWD | chpasswd"
    chroot "${MNTDIR}/" /bin/bash -c "chsh -s /bin/bash $USERNAMEPWD"
}
