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
GENTOO_ARCH="arm64"
GENTOO_STAGE3="arm64"
GRUB_PLATFORMS=pc

TARGET_DISK=/dev/sda
disk1="${TARGET_DISK}1"
disk2="${TARGET_DISK}2"
TARGET_BOOT_SIZE=1GiB
TARGET_ROOT_SIZE=20GiB
TARGET_SWAP_SIZE=10GiB
# Home will be rest of remaining space 

echo "\n"
echo "### Setting time..."
chronyd -q

echo "\n"
echo "### Creating partitions..."
parted -s -a optimal ${TARGET_DISK} \  mklabel gpt \
  mkpart primary 0% ${TARGET_BOOT_SIZE} \
  mkpart primary 1GiB 100% \
echo "### Formatting partitions..."
yes | mkfs.vfat -F 32 ${TARGET_DISK}1
yes | mkfs.btrfs -f ${TARGET_DISK}2

echo "\n"
echo "### Setting up encrypted physical volume"
cryptsetup luksFormat "$disk2"
cryptsetup open --type luks "$disk2" lvm
pvcreate --dataalignment 1m /dev/mapper/lvm
vgcreate vg0 /dev/mapper/lvm

echo "\n"
echo "### Creating logical volumes for home/root within encrypted physical volume..."
lvcreate -L ${TARGET_ROOT_SIZE} vg0 -n lv-root 
lvcreate -L ${TARGET_SWAP_SIZE} vg0 -n lv-swap
lvcreate -l 100%FREE vg0 -n lv-home

echo "\n"
echo "### Activating logic volumes..."
modprobe dm_mod # Load necessary modules into memory
vgscan # Check that kernel realizes that we just read in an LVM 
yes | vgchange -ay # Activate logical volume groups

echo "\n"
echo "### Setting filesystem for root/home/swap logical volumes..."
yes | mkfs.btrfs /dev/vg0/lv-root
yes | mkfs.btrfs /dev/vg0/lv-home
yes | mkfs.btrfs /dev/vg0/lv-swap
mkswap /dev/vg0/lv-swap
swapon /dev/vg0/lv-swap

echo "\n"
echo "### Mounting partitions..."
mkdir -p /mnt/gentoo
mkdir -p /mnt/boot && mount ${TARGET_DISK}1 /mnt/boot
mkdir -p /mnt/gentoo/root && mount /dev/vg0/lv-root /mnt/gentoo/root
mkdir -p /mnt/gentoo/home && mount /dev/vg0/lv-home /mnt/gentoo/home
mkdir -p /mnt/gentoo/efi && mount $disk1 /mnt/gentoo/efi

echo "\n"
echo "### Downloading and unpacking stage3 tarball"
cd /mnt/gentoo
# Stage 3 with openrc
if [[ $GENTOO_ARCH == "amd64" ]]; then 
    base_flags="-march=native -mtune=native -Ofast -pipe -flto"
    wget "https://distfiles.gentoo.org/releases/amd64/autobuilds/20231217T170203Z/stage3-x32-openrc-20231217T170203Z.tar.xz"
    wait
elif [[ $GENTOO_ARCH == "arm64" ]]; then
    base_flags="-mcpu=native -Ofast -pipe -flto"
    wget "https://distfiles.gentoo.org/releases/arm64/autobuilds/20231218T134654Z/stage3-arm64-openrc-20231218T134654Z.tar.xz"
    wait
fi
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
wait

echo "\n"
echo "### Configuring make.conf"
make_conf="/mnt/gentoo/etc/portage/make.conf"
cd /mnt/gentoo/etc/portage
touch $make_conf
wget https://github.com/kehali-woldemichael/Linux_Auto-Install/raw/main/gentoo_make.conf
cd /mnt/gentoo

wait
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/ #  Copy DNS info
wait

echo "\n"
echo "### Mounting file system"
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run 
wait

echo "\n"
echo "### Entering the new environment"

# Stage 2 of install
wget https://github.com/kehali-woldemichael/Linux_Auto-Install/raw/main/gentoo-2.sh
chmod +x gentoo-2.sh
wait
chroot /mnt/gentoo /bin/bash 
