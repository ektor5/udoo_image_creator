# Udoo Image Creator 20.04
> Script for the creation of an Ubuntu 20.04 for the UDOO Neo SBC.

This script uses debootstrap to create a minimal Ubuntu 20.04 rootfs then it configures it to make it compatible with the UDOO neo board. It uses a pre-compiled 4.14 kernel and u-boot.

## ![](header.png)

## Installation

To execute this script you only have to clone this repository and run the main script as root, you will be asked to download dependencies if necessary (this feature is only available on Ubuntu-based distros). It will then do its magic and you'll find your new and shiny image on the root of the repo, alongside the main script.

## Usage example

```sh
sudo ./udoo_image_create_v2.sh
```

## Development setup

This script requires:

    - debootsrap
    - qemu-debootstrap
    - qemu-arm-static

## WIP/Not working
    - Display LVDS
    - OTG

## Release History


* 0.2.0
    * Updated to Ubuntu 20.04
* 0.1.0
    * Image creator for Ubuntu 18.04


## Meta

Tommaso Perondi – tommaso.perondi@delirium.dev

Distributed under the GNU General Public License v3.0 license.


## Contributing

1. Fork it (<https://github.com/tommaso-perondi/udoo_image_creator>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
