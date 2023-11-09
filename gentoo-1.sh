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
GRUB_PLATFORMS=pc

TARGET_DISK=/dev/vda
TARGET_BOOT_SIZE=1GiB
TARGET_ROOT_SIZE=15GiB
# Home will be rest of remaining space 

echo "### Checking configuration..." # Can add later

echo "### Setting time..."
chronyd -q

echo "### Creating partitions..."
parted -s -a optimal ${TARGET_DISK} \
  mklabel gpt \
  mkpart primary 0% ${TARGET_BOOT_SIZE} \
  mkpart primary 1GiB 100% \
echo "### Formatting partitions..."
yes | mkfs.vfat -F 32 ${TARGET_DISK}1
yes | mkfs.xfs -f ${TARGET_DISK}2

echo "### Setting up encrypted physical volume"
cryptsetup luksFormat /dev/vda2
cryptsetup open --type luks /dev/vda2 lvm
pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm
echo "### Creating logical volumes for home/root within encrypted physical volume..."
lvcreate -L ${TARGET_ROOT_SIZE} vg0 -n lv-root 
lvcreate -l 100%FREE vg0 -n lv-home
echo "### Activating home/root logic volumes..."
modprobe dm_mod # Load necessary modules into memory
vgscan # Check that kernel realizes that we just read in an LVM 
yes | vgchange -ay # Activate logical volume groups
echo "### Setting filesystem for root/home logical volumes..."
yes | mkfs.xfs /dev/vg0/lv-root
yes | mkfs.xfs /dev/vg0/lv-home

echo "### Mounting partitions..."
mkdir -p /mnt/boot && mount ${TARGET_DISK}1 /mnt/boot
mkdir -p /mnt/root && mount /dev/vg0/lv-root /mnt/root
mkdir -p /mnt/home && mount /dev/vg0/lv-home /mnt/home



