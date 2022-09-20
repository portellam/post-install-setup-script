## Description

## How-to
* To install root scripts, execute:

        sudo bash sudo-install.bash

* To install user scripts, execute:

        bash user-install.bash

## Features
* Distro-specific
    * Modify software repository sources (APT)
    * Add/Ignore alternative repo sources (Flathub, Snap)
    * Install listed software by given category (of all sources)
        * Development
        * Games
        * Internet-based and Communication
        * Multi-media
        * Office
        * Prism-break (EFF recommended for user-privacy)
        * Security
        * Software suites
        * Tools
        * VGA/GPU drivers
        * other/unsorted

* Distro-agnostic
    * Add Systemd services to machine
    * Clone Git repositories
    * Execute scripts of given Git repos
    * Append to Cron
    * Security-hardening
    * Firewall setup

## To-do
* lots of work to be done
* make processes that can be distro-agnostic, more-so