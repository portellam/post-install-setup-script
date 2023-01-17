## Description
Post-install changes to a Linux system. Distro-agnostic (Debian-optimized).

## How-to
* To execute setup as sudo/root, execute:

        sudo bash installer.bash

* To execute setup as user, execute:

        bash installer.bash

## Main logic
[1] Check if user is root or not (set boolean).

[2] Distro-agnostic setup; Check if system is a recognized Linux distribution (set string).

[3] Setup Software sources and installation.

[4] Setup Git repositories.

[5] Setup system.

## Middle-man logic
[3]

    * Check current system is...
        * Debian Linux => Modify Debian APT sources.
    * Test network connection.
    * If user is root...
        * Install from Linux package manager sources (if system is recognized and lists are available). [A]
    * Else...
        * Install from Flathub (security measure; install as user is more secure than system-wide). [A]

[4]

    * Test network connection.
    * Clone Git repositories.
    * Install scripts from Git repositories (different for root and user).

[5]

    * Test network connection.
    * If user is root...
        * Modify SSH.
        * Modify system security.
        * Add SystemD services.
        * Add Cron jobs.

## Sources

**[A]** Install listed software by given category (of all sources)
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