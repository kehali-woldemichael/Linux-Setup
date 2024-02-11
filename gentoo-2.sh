#!/bin/sh
# Stage 2 of install

source /etc/profile 
export PS1="(chroot) ${PS1}"

echo "\n"
echo "### Configuring Portage"
emerge-webrsync # Installing a Gentoo ebuild repository snapshot from the web
wait
emerge --sync # Updating the Gentoo ebuild repository
wait

echo "\n"
echo "### Configuring Portage"
eselect profile list | grep -v desktop | grep -v systemd | grep -v musl | grep -v split-usr | grep -v big-endian | grep -v hardened 
read -p "Profile: " profile
eselect profile set "$profile"
emerge --ask --verbose --update --deep --newuse @world
emerge --info | grep ^USE > /etc/portage/make.conf

echo "\n"
echo "### Setting CPU FLAGS"
emerge --ask app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
