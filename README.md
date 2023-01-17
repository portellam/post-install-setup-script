## Description
Post-install changes to a Linux system. Distro-agnostic (Debian-optimized).

## How-to
* To execute setup as sudo/root, execute:

        sudo bash installer.bash

* To execute setup as user, execute:

        bash installer.bash

## Main logic
* Check if user is root or not (set boolean).

* Distro-agnostic setup; Check if system is a recognized Linux distribution (set string).

* Setup Software sources and installation. [A]

* Setup Git repositories. [B]

* Setup system. [C]

## Middle-man logic
#### [A]
* Check current system is...
    * Debian Linux => Modify Debian APT sources.
* Test network connection.
* If user is root...
    * Install from Linux package manager sources (if system is recognized and lists are available). [1]
* Else...
    * Install from Flathub (security measure; install as user is more secure than system-wide). [1]

#### [B]
* Test network connection.
* Clone Git repositories.
* Install scripts from Git repositories (different for root and user).

#### [C]
* Test network connection.
* If user is root...
    * Modify SSH.
    * Modify system security.
    * Add SystemD services.
    * Add Cron jobs.

## Sources
#### [1] Install listed software by given category (of all sources)
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