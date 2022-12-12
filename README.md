## Description
Post-install changes to a Debian Linux system.

## How-to
* To execute setup as sudo/root, execute:

        sudo bash installer.bash

* To execute setup as user, execute:

        bash installer.bash

## Features
* Distro-specific
    * Modify software repository sources (APT)
    * Install APT software packages **[1]**
    * Update APT packages

* Distro-agnostic
    * Add/Ignore alternative repo sources (Flathub, Snap)
    * Install Flatpak/Snap software packages **[1]**
    * Update Flatpak/Snap packages
    * Add Systemd services to machine
    * Clone Git repositories
    * Execute scripts of given Git repos
    * Append to Cron
    * Security-hardening
    * Firewall setup

* **[1]** Install listed software by given category (of all sources)
    * Development
    * Games
    * Internet-based and Communication
    * Multi-media
    * Office
    * Prism-break (EFF, recommended for user-privacy)
    * Security
    * Software suites
    * Tools
    * VGA/GPU drivers
    * other/unsorted

## DISCLAIMER
Tested on Debian Linux.

## To-Do
* lots of work to be done
* make processes that can be distro-agnostic, more-so