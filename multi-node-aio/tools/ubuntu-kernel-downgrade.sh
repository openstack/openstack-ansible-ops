#!/bin/sh
#eg. KERNEL_VERSION="3.13.0-98"
KERNEL_VERSION=${KERNEL_VERSION:-false}

if [[ "${KERNEL_VERSION}" = false ]]; then
  echo "Please setup the KERNEL_VERSION before running this script"
  exit 1
fi

sudo apt-get update
sudo aptitude install -y linux-image-${KERNEL_VERSION}-generic \
     linux-headers-${KERNEL_VERSION} linux-image-extra-${KERNEL_VERSION}-generic

sudo sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Ubuntu>Ubuntu, with Linux ${KERNEL_VERSION}-generic\"/" /etc/default/grub
sudo update-grub
sudo reboot
