#!/bin/sh
# Stage 2 of install

# Stage 2 of install
chroot /mnt/gentoo /bin/bash 
source /etc/profile 
export PS1="(chroot) ${PS1}"

# Preparing for a bootloader 
mkdir /efi 
mount /dev/sda1 /efi 

echo "\n"
echo "### Configuring Portage"
emerge-webrsync # Installing a Gentoo ebuild repository snapshot from the web
wait
emerge --sync # Updating the Gentoo ebuild repository
wait

echo "\n"
echo "### Configuring Portage"
mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv1
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv2
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv3

emerge --ask --verbose --oneshot app-portage/mirrorselect
#mirrorselect -i -o >> /etc/portage/make.conf

eselect profile list | grep -v desktop | grep -v systemd | grep -v musl | grep -v split-usr | grep -v big-endian | grep -v hardened 
read -p "Profile: " profile
eselect profile set "$profile"

#emerge --info | grep ^USE >> /etc/portage/make.conf
#emerge --ask --verbose --update --deep --newuse @world


echo "\n"
echo "### Setting CPU FLAGS"
# (fix) emerge --ask app-portage/cpuid2cpuflags
# (fix) echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

echo "US/Eastern" > /etc/timezone
