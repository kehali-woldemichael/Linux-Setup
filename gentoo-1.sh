#!/bin/sh

##
# GENTOO QUICK INSTALLER
#
# Read more: http://www.artembutusov.com/gentoo-linux-quick-installer-script/
#
# Usage:
#
# export OPTION1=VALUE1
# export OPTION2=VALUE2
# ./gentoo-quick-installer.sh
#
# Options:
#
# USE_LIVECD_KERNEL - 1 to use livecd kernel (saves time) or 0 to build kernel (takes time)
# SSH_PUBLIC_KEY - ssh public key, pass contents of `cat ~/.ssh/id_rsa.pub` for example
# ROOT_PASSWORD - root password, only SSH key-based authentication will work if not set
##

set -e

GENTOO_MIRROR="http://distfiles.gentoo.org"
GENTOO_ARCH="amd64"
GENTOO_STAGE3="amd64"

TARGET_DISK=/dev/vda
TARGET_BOOT_SIZE=1G
TARGET_ROOT_SIZE=24G

GRUB_PLATFORMS=pc

echo "### Checking configuration..." # Can add later

echo "### Setting time..."
chronyd -q

echo "### Creating partitions..."
parted -s -a optimal ${TARGET_DISK} \
  mklabel gpt \
  mkpart primary 0% 1GiB \
  mkpart primary 1GiB 100% \

echo "### Formatting partitions..."
yes | mkfs.vfat -F 32 ${TARGET_DISK}1
yes | mkfs.xfs ${TARGET_DISK}2

echo "### Labeling partitions..."
e2label ${TARGET_DISK}1 boot
e2label ${TARGET_DISK}3 volgroup0

echo "### Mounting partitions..."
mkdir -p /mnt/gentoo/boot && mount ${TARGET_DISK}1 /mnt/gentoo/boot
mkdir -p /mnt/gentoo && mount ${TARGET_DISK}2 /mnt/gentoo
