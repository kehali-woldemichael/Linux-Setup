#!/bin/sh

# GENTOO QUICK INSTALLER

set -e

GENTOO_MIRROR="http://distfiles.gentoo.org"
GENTOO_ARCH="arm64"
GENTOO_STAGE3="arm64"
GRUB_PLATFORMS=pc

TARGET_DISK=/dev/sda
disk1="${TARGET_DISK}1"
disk2="${TARGET_DISK}2"

# Home will be rest of remaining space 
TARGET_BOOT_SIZE=1GiB
POST_BOOT_SIZE=2GiB
TARGET_ROOT_SIZE=20GiB
TARGET_SWAP_SIZE=16GiB

echo "\n"
echo "### Setting time..."
chronyd -q

echo "\n"
echo "### Creating partitions..."
parted -s -a optimal $TARGET_DISK \  mklabel gpt \
  mkpart primary 0% $TARGET_BOOT_SIZE \
  mkpart primary $POST_BOOT_SIZE 100% \
echo "### Formatting partitions..."
yes | mkfs.vfat -L efi -F32 $disk1
yes | mkfs.btrfs -L rootfs -f $disk2

echo "\n"
echo "### Setting up encrypted physical volume"
cryptsetup luksFormat $disk2
cryptsetup open --type luks $disk2 lvm
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
yes | mkfs.f2fs /dev/vg0/lv-swap
mkswap /dev/vg0/lv-swap
swapon /dev/vg0/lv-swap

echo "\n"
echo "### Mounting ..."

mkdir -p /mnt/gentoo && mount -o compress-force=zstd:3 /dev/vg0/lv-root /mnt/gentoo
mkdir -p /mnt/gentoo/efi && mount $disk1 /mnt/gentoo/efi
mkdir -p /mnt/gentoo/home && mount -o compress-force=zstd:3 /dev/vg0/lv-home /mnt/gentoo/home
# Swap is not mounted to the filesystem like a device file. 

# Mount proc, dev and shm filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run && mount --make-slave /mnt/gentoo/run 
test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
chmod 1777 /dev/shm
wait

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
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-2.sh
chmod +x gentoo-2.sh
wait

echo "\n"
echo "### Configuring make.conf"
make_conf="/mnt/gentoo/etc/portage/make.conf"
cd /mnt/gentoo/etc/portage
wget https://github.com/kehali-woldemichael/Linux-Install/raw/main/gentoo_make.conf
wait
cd /mnt/gentoo

echo "\n"
echo "### Preparing to enter the new environment"

# Preparing networking 
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/resolv.conf # Copy DNS info
wait

# Stage 2 of install
chroot /mnt/gentoo /bin/zsh 
