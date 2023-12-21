#!/bin/sh
# Stage 2 of install

source /etc/profile 
export PS1="(chroot) ${PS1}"

echo "\n### Preparing for a bootloader"
mkdir /efi
mount "$disk1" /efi 

echo "\n### Configuring Portage"
emerge-webrsync # Installing a Gentoo ebuild repository snapshot from the web
emerge --sync # Updating the Gentoo ebuild repository

echo "\n### Configuring Portage"
eselect profile list
read -p "Select profile: " profile_choice
eselect profile set "$profile_choice"
emerge --ask --verbose --update --deep --newuse @world
emerge --info | grep ^USE > /etc/portage/make.conf

echo "\n### Printing current make.conf"
cat /etc/portage/make.conf
echo "\n"

emerge --ask app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
