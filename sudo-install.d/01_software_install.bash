#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_file1=$(echo ${0##/*})
            str_file1=$(echo $str_file1 | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'. Exiting."
            exit 1
        fi
    }

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
        str_input1=${str_input1:0:1}
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!

            else
                echo -en "\t$1 [Y/n]: "
                read str_input1

                str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
                str_input1=${str_input1:0:1}
            fi

            case $str_input1 in
                "Y"|"N")
                    break;;

                *)
                    echo -en "\tInvalid input. ";;
            esac

            ((int_count++))         # increment counter
        done
    }


# check linux distro #
    function CheckCurrentDistro
    {
        echo -en "Linux distribution found ($(lsb_release -i -s)) "

        # Debian, Ubuntu
        if [[ -e $(lsb_release -is | tr '[:upper:]' '[:lower:]' | grep -Ev 'debian|ubuntu') ]]; then
            echo -e "is compatible with setup. Continuing."

        else
            echo -e "is not compatible with setup. Exiting."
            exit 1
        fi
    }

# install Debian software #
    function InstallFromDebianRepos
    {
        echo -e "Installing from distribution repositories."

        # parameters #
        ReadInput "Auto-accept install prompts? "

        if [[ $str_input1 == "Y" ]]; then
            str_args="-y"

        else
            str_args=""
        fi

        sudo apt clean
        sudo apt update
        sudo apt full-upgrade $str_args

        # Qt DE (KDE-plasma, LXQT)
        str_aptCheck=""
        str_aptCheck=$(sudo apt list --installed plasma-desktop lxqt)

        if [[ $str_aptCheck != "" ]]; then
            sudo apt install -y plasma-discover-backend-flatpak
        fi

        # GNOME DE (gnome, XFCE)
        str_aptCheck=""
        str_aptCheck=$(sudo apt list --installed gnome xfwm4)

        if [[ $str_aptCheck != "" ]]; then
            sudo apt install -y gnome-software-plugin-flatpak
        fi

        echo

        # apps #
        # NOTE: update here!

        # parameters #
        str_aptAll=""
        str_aptDeveloper=""
        str_aptDrivers="steam-devices"
        str_aptGames=""
        str_aptInternet="firefox-esr filezilla"
        str_aptMedia="vlc"
        str_aptOffice="libreoffice"
        str_aptPrismBreak=""
        str_aptSecurity="fail2ban gufw ssh ufw"
        str_aptSuites="debian-edu-install science-all"
        str_aptTools="apcupsd bleachbit cockpit curl flashrom git grub-customizer java-common lm-sensors neofetch python3 qemu rtl-sdr synaptic unzip virt-manager wget wine youtube-dl zram-tools"
        str_aptUnsorted=""
        str_aptVGAdrivers="nvidia-detect xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-cirrus xserver-xorg-video-fbdev xserver-xorg-video-glide xserver-xorg-video-intel xserver-xorg-video-ivtv-dbg xserver-xorg-video-ivtv xserver-xorg-video-mach64 xserver-xorg-video-mga xserver-xorg-video-neomagic xserver-xorg-video-nouveau xserver-xorg-video-openchrome xserver-xorg-video-qxl/ xserver-xorg-video-r128 xserver-xorg-video-radeon xserver-xorg-video-savage xserver-xorg-video-siliconmotion xserver-xorg-video-sisusb xserver-xorg-video-tdfx xserver-xorg-video-trident xserver-xorg-video-vesa xserver-xorg-video-vmware"

        # install apps #
        if [[ $str_aptUnsorted != "" ]]; then
            echo -e "Select given software?"

            if [[ $str_aptUnsorted == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptUnsorted | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptUnsorted | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptUnsorted"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptUnsorted "
            fi

            echo
        fi

        if [[ $str_aptDeveloper != "" ]]; then
            echo -e "Select Development software?"

            if [[ $str_aptDeveloper == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptDeveloper | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptDeveloper | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptDeveloper"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptDeveloper "
            fi

            echo
        fi

        if [[ $str_aptGames != "" ]]; then
            echo -e "Select games?"

            if [[ $str_aptGames == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptGames | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptGames | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptGames"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptGames "
            fi

            echo
        fi

        if [[ $str_aptInternet != "" ]]; then
            echo -e "Select Internet software?"

            if [[ $str_aptInternet == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptInternet | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptInternet | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptInternet"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptInternet "
            fi

            echo
        fi

        if [[ $str_aptMedia != "" ]]; then
            echo -e "Select multi-media software?"

            if [[ $str_aptMedia == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptMedia | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptMedia | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptMedia"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptMedia "
            fi

            echo
        fi

        if [[ $str_aptOffice != "" ]]; then
            echo -e "Select office software?"

            if [[ $str_aptOffice == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptOffice | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptOffice | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptOffice"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptOffice "
            fi

            echo
        fi

        if [[ $str_aptPrismBreak != "" ]]; then
            echo -e "Select recommended Prism break software?"

            if [[ $str_aptPrismBreak == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptPrismBreak | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptPrismBreak | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptPrismBreak"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptPrismBreak "
            fi

            echo
        fi

        if [[ $str_aptSecurity != "" ]]; then
            echo -e "Select security tools?"

            if [[ $str_aptSecurity == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptSecurity | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptSecurity | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptSecurity"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptSecurity "
            fi

            echo
        fi

        if [[ $str_aptSuites != "" ]]; then
            echo -e "Select software suites?"

            if [[ $str_aptSuites == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptSuites | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptSuites | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptSuites"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptSuites "
            fi

            echo
        fi

        if [[ $str_aptTools != "" ]]; then
            echo -e "Select software tools?"

            if [[ $str_aptTools == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptTools | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptTools | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptTools"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptTools "
            fi

            echo
        fi

        if [[ $str_aptVGAdrivers != "" ]]; then
            echo -e "Select VGA drivers?"

            if [[ $str_aptVGAdrivers == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_aptVGAdrivers | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_aptVGAdrivers | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_aptVGAdrivers"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_aptAll+="$str_aptVGAdrivers "
            fi

            echo
        fi

        if [[ $str_aptAll != "" ]]; then
            sudo apt install $str_args $str_aptAll
        fi

        # clean up #
        # sudo apt autoremove $str_args
    }

# install alternative software repos #
    function EnableAndInstallFromAltRepos
    {
        echo -e "Installing from alternative repositories."

        # parameters #
        ReadInput "Auto-accept install prompts? "

        if [[ $str_input1 == "Y" ]]; then
            str_args="-y"

        else
            str_args=""
        fi

        # apps #
        # NOTE: update here!
        str_flatpakAll=""
        str_flatpakUnsorted="com.adobe.Flash-Player-Projector com.calibre_ebook.calibre com.makemkv.MakeMKV com.obsproject.Studio com.poweriso.PowerISO com.stremio.Stremio com.valvesoftware.Steam com.valvesoftware.SteamLink com.visualstudio.code com.vscodium.codium fr.handbrake.ghb io.github.Hexchat io.gitlab.librewolf-community nz.mega.MEGAsync org.bunkus.mkvtoolnix-gui org.filezillaproject.Filezilla org.freedesktop.LinuxAudio.Plugins.TAP org.freedesktop.LinuxAudio.Plugins.swh org.freedesktop.Platform org.freedesktop.Platform.Compat.i386 org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL32.nvidia-460-91-03 org.freedesktop.Platform.VAAPI.Intel.i386 org.freedesktop.Platform.ffmpeg-full org.freedesktop.Platform.openh264 org.freedesktop.Sdk org.getmonero.Monero org.gnome.Platform org.gtk.Gtk3theme.Breeze org.kde.KStyle.Adwaita org.kde.Platform org.kde.digikam org.kde.kdenlive org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.Thunderbird org.openshot.OpenShot org.videolan.VLC org.videolan.VLC.Plugin.makemkv org.libretro.RetroArch"
        str_flatpakPrismBreak=""   # include from all, monero etc.
        str_snapAll=""
        str_snapUnsorted=""

        if [[ $str_flatpakUnsorted != "" ]]; then
            echo -e "Select given Flatpak software?"

            if [[ $str_flatpakUnsorted == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_flatpakUnsorted | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_flatpakUnsorted | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_flatpakUnsorted"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_flatpakAll+="$str_flatpakUnsorted "
            fi

            echo
        fi

        if [[ $str_flatpakPrismBreak != "" ]]; then
            echo -e "Select recommended Prism Break Flatpak software?"

            if [[ $str_flatpakPrismBreak == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_flatpakPrismBreak | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_flatpakPrismBreak | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_flatpakPrismBreak"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_flatpakAll+="$str_flatpakPrismBreak "
            fi

            echo
        fi

        if [[ $str_snapUnsorted != "" ]]; then
            echo -e "Select given Snap software?"

            if [[ $str_snapUnsorted == *" "* ]]; then
                declare -i int_i=1

                while [[ $(echo $str_snapUnsorted | cut -d ' ' -f$int_i) ]]; do
                    echo -e "\t"$(echo $str_snapUnsorted | cut -d ' ' -f$int_i)
                    ((int_i++))     # counter
                done

            else
                echo -e "\t$str_snapUnsorted"
            fi

            ReadInput

            if [[ $str_input1 == "Y" ]]; then
                str_snapAll+="$str_snapUnsorted "
            fi

            echo
        fi

        sudo apt install -y flatpak snapd
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

        if [[ -e $(apt list --installed flatpak) ]]; then
            if [[ $str_flatpakAll != "" ]]; then
                echo -e "Install selected Flatpak apps?"
                sudo flatpak install flathub $str_args $str_flatpakAll
            fi

        else
            echo -e "WARNING: Flatpak not installed! Skipping."
        fi

        if [[ -e 'apt list --installed snapd' ]]; then
            if [[ $str_snapAll != "" ]]; then
                echo -e "Install selected Snap apps?"
                sudo snap install $str_args $str_snapAll
            fi

        else
            echo -e "WARNING: Snapd not installed! Skipping."
        fi
    }

# main #

    # NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    # call functions #
    CheckIfUserIsRoot
    CheckCurrentDistro
    InstallFromDebianRepos
    EnableAndInstallFromAltRepos

    echo -e "\nWARNING: If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"

    IFS=$SAVEIFS        # reset IFS
    echo -e "Exiting."
    exit 0