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
  * Modify /etc/modules
  * Modify /etc/modprobe.d/
* GRUB
  * Add commented options, including VFIO
  * TO-DO: Add custom GRUB entries
* Xorg
  * Add bash scripts to /etc/rc.local, to be used by custom GRUB entries for VFIO
* Libvirt
  * TO-DO: Modify /etc/libvirt/qemu.conf
* Crontab
  * WIP

## uid 1000 script
WIP
