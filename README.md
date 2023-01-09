## Description
Post-install changes to a Debian Linux system.

## How-to
* To execute setup as sudo/root, execute:

        sudo bash installer.bash

* To execute setup as user, execute:

        bash installer.bash

## Sudo Features
* Ask user to change Debian software repositories, and update
* Ask user to install recommended software **[1]**
    * Debian APT packages
    * Flatpak apps
    * Sudo-only Git scripts
* Ask user to make recommended system security-hardening / changes
    * Enable/Disable USB, thunderbolt, etc. interfaces
    * Enable/Change/Disable SSH
    * Enable UFW firewall
    * Parse local '.files' directory for changes to:
        * Cron
        * System files
        * System services

## User Features
* Ask user to install recommended Git scripts

## Sources

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
Tested on Debian Linux. Work-in-progress.