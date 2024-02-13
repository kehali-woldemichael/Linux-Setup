# Kernel Confirguration 
emerge --ask app-portage/gentoolkit # provides "equery" command for checking package info
emerge --ask app-editors/neovim
emerge --ask app-misc/ranger # have to unmask for arm64
emerge --ask app-misc/trash-cli


#emerge --ask sys-kernel/linux-firmware
# Install kernel sources ... for manual kernel configuration
emerge --ask sys-kernel/linux-firmware
emerge --ask sys-kernel/gentoo-sources
emerge --ask sys-apps/pciutils

# Distribution kernel 
# Enable dracut support
emerge --ask sys-kernel/installkernel 
sys-kernel/installkernel dracut
# To build a kernel with Gentoo patches from source
emerge --ask sys-kernel/gentoo-kernel


# Open menu-driven configuration screen
# cd /usr/src/linux*
# make menuconfig # follow instructions on https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Alternative:_Manual_configuration


