# new-debian
Personal Bash scripts to run at first-time setup for Debian Linux.

## sudo script
* Dependencies
  * Modify apt sources.list
  * Install apt packages
  * Install flatpak packages
* Systemctl
  * Enable/Disable specific services
* SSH
  * Modify SSH port
* UFW
  * Add custom rules, including previous SSH port
* Git
  * Clone repos to be used in GitScripts
* GitScripts
  * foundObjects/zram-swap => install
  * pyllyukko/user.js => apply system-wide user.js for firefox-esr
  * StevenBlack/hosts => append to local hosts file
* VFIO
  * TO-DO: Parse user input for VFIO: IOMMU ID, PCI IDs, and kernel driver. 
  * Modify */etc/modules* for non-VGA devices and devices to be always grabbed by vfio-pci (depending on use-case and GRUB boot option)
  * Modify */etc/modprobe.d/* including *kvm-amd.conf*,*kvm-intel.conf*
* GRUB
  * Add commented options, including VFIO
  * TO-DO: Add custom GRUB entries for different use-cases, example: alternating VGA devices
* Xorg
  * Add bash scripts to /etc/rc.local, to be used by custom GRUB entries for VFIO
* Libvirt
  * TO-DO: Parse */dev/input/by-id* 
  * TO-DO: Modify */etc/libvirt/qemu.conf*
* Crontab
  * WIP

## uid 1000 script
WIP
