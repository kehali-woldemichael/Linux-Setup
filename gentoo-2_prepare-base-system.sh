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
mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv1
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv2
wget https://github.com/kehali-woldemichael/Linux-Setup/raw/main/gentoo-make.conf-lv3

# Installing a Gentoo ebuild repository snapshot from the web
emerge-webrsync 
wait
# Identify and select 3 fastest mirror options
emerge --ask --verbose --oneshot app-portage/mirrorselect
wait
# Restrict by region? ... country?
#mirrorselect -s3 -b10 -D 
echo 'GENTOO_MIRRORS="https://mirrors.mit.edu/gentoo-distfiles/"' >> /etc/portage/make.conf
# Updating the Gentoo ebuild repository
emerge --sync --quiet
wait

#  Choosing the right profile
eselect profile list | grep -v desktop | grep -v systemd | grep -v musl | grep -v split-usr | grep -v big-endian | grep -v hardened 
read -p "Profile: " profile
eselect profile set "$profile"

#emerge --info | grep ^USE >> /etc/portage/make.conf
#emerge --ask --verbose --update --deep --newuse @world
#emerge --depclean


echo "\n"
echo "### Setting CPU FLAGS"
emerge --ask app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

# Setting locale 
echo "US/Eastern" >> /etc/timezone
nano /etc/locale.gen
locale-gen
eselect locale list
read -p "Locale #: " locale_target
eselect locale set $locale_target
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
