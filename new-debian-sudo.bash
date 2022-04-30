#!/bin/bash sh

## METHODS start ##

function 00_Prompt {

    echo "Prompt: Start."
    
    # PARAMETERS
    bool_isManual=true
    declare -i int_count=0
    
    # MANUAL PROMPT
    while true; do
        echo "Prompt: Do you wish to execute this script manually? [Y/n]"
        read str_input
        
        # STRING TO UPPER
        str_input=$(echo $str_input | tr '[:lower:]' '[:upper:]')
        #if [[ $str_input -eq "YES" || $str_input -eq "NO" ]]; then
            #str_input=${str_input:0:1}
        #fi
        str_input=${str_input:0:1}
        
        case $str_input in
            "Y")
            
                echo "Prompt: Executing script manually."
                bool_isManual=true
                break
                
            ;;
            "N")
            
                echo "Prompt: Executing script automatically."
                bool_isManual=false
                break
                
            ;;
            *)
            
                echo "Prompt: Invalid input!"
                
            ;;
        esac
        
        # COUNTER
        ((int_count++))
        
        # AFTER THREE TRIES, EXIT
        if [[ $int_count -ge 3 ]]; then
        
            echo "Prompt: Exceeded max attempts! Executing script manually..."
            bool_isManual=true
            break
            
        fi
    done
    
    echo "Prompt: End."
    
}

function 01A_Dependencies {

    echo "Dependencies: Start."
    
    # FIND CURRENT RELEASE CODENAME
    str_releaseName=$(lsb_release -a | grep Codename)
    ((int_releaseName=${#str_releaseName}-10))
    str_releaseName=(${str_releaseName:10:$int_releaseName})
    
    # FIND CURRENT RELEASE BRANCHNAME
    str_releaseVer=$(lsb_release -a | grep Release)
    ((int_releaseVer=${#str_releaseVer}-9))
    str_releaseVer=(${str_releaseVer:9:$int_releaseVer})
    echo $str_releaseVer

    # SET WORKING FILE
    str_file="/etc/apt/sources.list"
    
    # CREATE BACKUP OR RESTORE FROM BACKUP
    if [ -d $str_file ]; then
        cp $str_file $str_file'_old'
    else
        cp $str_file'_old' $str_file
    fi
    
    while true; do
        
        # MANUAL PROMPT
        if $bool_isManual; then
            echo "Dependencies: Enter one valid option or none for default (Current branch: $str_releaseName)."
            echo "Release branches:"
            echo "  stable      == $str_releaseName (with non-free)"
            echo "  testing     (with non-free)"
            echo "Others:"
            echo "  backports   == $str_releaseName-backports (with non-free)"
            echo "Enter option:"
            read str_input        
            # STRING TO LOWERCASE
            str_input=$(echo $str_input | tr '[:upper:]' '[:lower:]')
        else
            str_input="backports"
        fi

        # APT SOURCES 
        declare -a arr_sources=(
"# debian $str_input"
"# See https://wiki.debian.org/SourcesList for more information."
"deb http://deb.debian.org/debian/ $str_input main non-free contrib"
"deb-src http://deb.debian.org/debian/ $str_input main non-free contrib"
$'\n'
"deb http://deb.debian.org/debian/ $str_input-updates main non-free contrib"
"deb-src http://deb.debian.org/debian/ $str_input-updates main non-free contrib"
$'\n'
"deb http://security.debian.org/debian-security/ $str_input-security main non-free contrib"
"deb-src http://security.debian.org/debian-security/ $str_input-security main non-free contrib"
"#"
)

        # COMMENT LINES FROM ORIGINAL TO TEMP FILE
        touch $str_file'_temp'
        while read str_line; do
            echo '#'$str_line >> $str_file'_temp'
        done < $str_file
        
        # COPY TEMP FILE TO ORIGINAL
        cat $str_file'_temp' > $str_file
        
        # DELETE OPTIONAL SOURCES FILE, IF IT EXISTS
        if [ ! -d '/etc/apt/sources.list.d/'$str_input'.list' ]; then
            rm '/etc/apt/sources.list.d/'$str_input'.list'
        fi
        
        
        # INPUT PROMPT
        case $str_input in
        
            # STABLE AND NON-FREE
            "stable")

                echo "Dependencies: Selected \"$str_input\"."

                 # LOOP THRU ARRAY
                int_line=${#arr_sources[@]}
                for (( int_index=0; int_index<$int_line; int_index++ )); do
                    str_line=${arr_sources[$int_index]}
                    echo $str_line >> '/etc/apt/sources.list.d/'$str_input'.list'
                done
                
                break;;
            
            # TESTING AND NON-FREE
            "testing")
                
                echo "Dependencies: Selected \"$str_input\"."

                 # LOOP THRU ARRAY
                int_line=${#arr_sources[@]}
                for (( int_index=0; int_index<$int_line; int_index++ )); do
                    str_line=${arr_sources[$int_index]}
                    echo $str_line >> '/etc/apt/sources.list.d/'$str_input'.list'
                done
                
                break;;

            # CURRENT BRANCH WITH BACKPORTS AND NON-FREE
            "backports")
            
                echo "Dependencies: Selected \"$str_input\"."
                
                # APT SOURCES 
                declare -a arr_sources=(
$'\n'
"# debian $str_releaseVer/$str_releaseName"
"# See https://wiki.debian.org/SourcesList for more information."
"deb http://deb.debian.org/debian/ $str_releaseName main non-free contrib"
"deb-src http://deb.debian.org/debian/ $str_releaseName main non-free contrib"
$'\n'
"deb http://deb.debian.org/debian/ $str_releaseName-updates main non-free contrib"
"deb-src http://deb.debian.org/debian/ $str_releaseName-updates main non-free contrib"
$'\n'
"deb http://security.debian.org/debian-security/ $str_releaseName-security main non-free contrib"
"deb-src http://security.debian.org/debian-security/ $str_releaseName-security main non-free contrib"
"#"
"# debian $str_releaseVer/$str_releaseName $str_input"
"deb http://deb.debian.org/debian $str_releaseName-$str_input main contrib non-free"
"deb-src http://deb.debian.org/debian $str_releaseName-$str_input main contrib non-free"
"#"
)

                 # LOOP THRU ARRAY
                int_line=${#arr_sources[@]}
                for (( int_index=0; int_index<$int_line; int_index++ )); do
                    str_line=${arr_sources[$int_index]}
                    echo $str_line >> $str_file
                done

                break;;
            
            # INVALID SELECTION
            *)
            
                echo "Dependencies: Invalid input!"
                
        esac
        
        ((int_count++))
        
        # AFTER THREE TRIES, EXIT
        if [[ $int_count -ge 3 ]]; then
        
            echo "Dependencies: Exceeded max attempts! Selected none."
            break
            
        fi
        
    done
    
    # REMOVE TEMP FILE
    rm $str_file'_temp'
    
    echo "Dependencies: End."
    
}

function 01B_Dependencies {

    echo "Dependencies: Start."

    # APT
    apt clean
    apt update
    
    # MANUAL PROMPT
    if $bool_isManual; then
        apt autoremove
        apt upgrade
    else
        apt autoremove -y
        apt upgrade -y
    fi
    
    # UNUSED
    str_aptRem="os-prober"
    
    # NOTE: any changes made, see SYSTEMD.
    # NOTE: update here!
    str_aptAdd="apcupsd bleachbit cockpit curl fail2ban flashrom flatpak firefox-esr filezilla git grub-customizer gufw java-common lm-sensors neofetch nvidia-detect python3 qemu rtl-sdr ssh synaptic ufw unzip virt-manager vlc wget wine youtube-dl zram-tools "
    
    # VIDEO DRIVERS
    str_aptAdd2="xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-cirrus xserver-xorg-video-fbdev xserver-xorg-video-glide xserver-xorg-video-intel xserver-xorg-video-ivtv-dbg xserver-xorg-video-ivtv xserver-xorg-video-mach64 xserver-xorg-video-mga xserver-xorg-video-neomagic xserver-xorg-video-nouveau xserver-xorg-video-openchrome xserver-xorg-video-qxl/ xserver-xorg-video-r128 xserver-xorg-video-radeon xserver-xorg-video-savage xserver-xorg-video-siliconmotion xserver-xorg-video-sisusb xserver-xorg-video-tdfx xserver-xorg-video-trident xserver-xorg-video-vesa xserver-xorg-video-vmware "
    
    # MANUAL PROMPT
    if $bool_isManual; then
        apt remove $str_aptRem
        apt install $str_aptAdd
        #apt install $str_aptAdd2
    else
        apt remove -y $str_aptRem
        apt install -y $str_aptAdd
        #apt install -y $str_aptAdd2
    fi
    
    # ADD FLATPAK REPO
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # NOTE: update here!
    str_flatpakAdd="com.adobe.Flash-Player-Projector com.calibre_ebook.calibre com.makemkv.MakeMKV com.obsproject.Studio com.poweriso.PowerISO com.stremio.Stremio com.valvesoftware.Steam com.valvesoftware.SteamLink com.visualstudio.code com.vscodium.codium fr.handbrake.ghb io.github.Hexchat io.gitlab.librewolf-community nz.mega.MEGAsync org.bunkus.mkvtoolnix-gui org.filezillaproject.Filezilla org.freedesktop.LinuxAudio.Plugins.TAP org.freedesktop.LinuxAudio.Plugins.swh org.freedesktop.Platform org.freedesktop.Platform.Compat.i386 org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL32.nvidia-460-91-03 org.freedesktop.Platform.VAAPI.Intel.i386 org.freedesktop.Platform.ffmpeg-full org.freedesktop.Platform.openh264 org.freedesktop.Sdk org.getmonero.Monero org.gnome.Platform org.gtk.Gtk3theme.Breeze org.kde.KStyle.Adwaita org.kde.Platform org.kde.digikam org.kde.kdenlive org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.Thunderbird org.openshot.OpenShot org.videolan.VLC org.videolan.VLC.Plugin.makemkv "
    
    # MANUAL PROMPT
    if $bool_isManual; then
        flatpak install flathub $str_flatpakAdd
    else
        flatpak install flathub -y $str_flatpakAdd
    fi
    
    echo "Dependencies: End."
    
}

function 02_Systemctl {
    echo "Systemctl: Start."
    declare -a arr_service=("apcupsd" "cockpit" "zramswap")     # NOTE: changes go here.
    int_service=${#arr_service[@]}
    if $bool_isManual; then
        for (( int_index=0; int_index<$int_service; int_index++ )); do
            str_service=${arr_service[$int_index]}
            declare -i int_count=0
            while [[ "$int_count" -le 2 ]]; do
                if [[ $int_count > 2 ]]; then
                    echo "Exceeded max attempts! Skipping '$str_service'..."
                    int_count=3
                fi
                echo "Do you wish to use $str_service service? (Y)es or (N)o:"
                read str_input
                str_input=$(echo $str_input | tr '[:lower:]' '[:upper:]')
                if [[ $str_input="YES" || $str_input="NO" ]]; then
                    str_input=${str_input:0:1}
                fi
                case $str_input in
                    "Y")
                        echo "Skipping '$str_service'..."
                        int_count=3
                    ;;
                    "N")
                        echo "Service '$str_service' to be disabled."
                        systemctl stop $str_service
                        systemctl disable $str_service
                        int_count=3
                    ;;
                    *)
                        echo "Invalid input!"
                        ((int_count++))
                    ;;
                esac
            done
        done
    else
        for (( int_index=0; int_index<$int_service; int_index++ )); do
            str_service=${arr_service[$int_index]}
            echo "Service '$str_service' to be disabled."
            systemctl stop $str_service
            systemctl disable $str_service
        done
    fi
    echo "Systemctl: End."
}

function 03_SSH {
    echo "SSH: Start."
    int_count=0
    while true; do
        if [ $int_count -gt 2 ]; then
            str_sshAlt=22
            echo "SSH: Exceeded max attempts! Value is set to default."
            break
        fi
        echo "SSH: Enter a new IP Port number for SSH:"
        read str_sshAlt
        if [ "$str_sshAlt" -eq "$str_sshAlt" ] 2> /dev/null; then
            if [ "$str_sshAlt" -eq 22 ]; then
                echo "SSH: Value is set to default."
                break
            fi
            if [ "$str_sshAlt" -gt 0 ]; then
                break
            fi
        else
            echo "SSH: Invalid input. First parameter must be an integer."            
        fi
        ((int_count++))
    done
    str_file="/etc/ssh/ssh_config"
    if [ -d $str_file'_old' ]; then
        cp $str_file $str_file'_old' 
    else
        cp $str_file'_old' $str_file
    fi
    echo $'\n#\nPort '$str_sshAlt >> $str_file
    str_file="/etc/ssh/sshd_config"
    if [ -d $str_file'_old' ]; then
        cp $str_file $str_file'_old' 
    else
        cp $str_file'_old' $str_file
    fi
    echo $'\n#\nPort '$str_sshAlt >> $str_file
    cat << 'EOF' >> $str_file
LoginGraceTime 1m
PermitRootLogin prohibit-password
MaxAuthTries 6
MaxSessions 2
EOF
    systemctl restart ssh sshd
    echo "SSH: End."
}

function 04_UFW {
    echo "UFW: Start."
    if [[ $str_sshAlt -eq 22 ]]; then
        sudo ufw limit from 192.168.1.0/24 to any port 22 proto tcp
    else
        sudo ufw deny ssh
        sudo ufw limit from 192.168.1.0/24 to any port $str_sshAlt proto tcp
    fi
    # NOTE: update here!
    sudo ufw allow dns
    sudo ufw allow from 192.168.1.0/24 to any port 2049
    sudo ufw allow from 192.168.1.0/24 to any port 3389
    sudo ufw allow from 192.168.1.0/24 to any port 9090 proto tcp   # cockpit
    sudo ufw allow from 192.168.1.0/24 to any port 137:138 proto udp
    sudo ufw allow from 192.168.1.0/24 to any port 139,445 proto tcp
    sudo ufw enable
    sudo ufw reload
    echo "UFW: End."
}

function 05_Git {
    echo "Updating GIT..."
    str_dir="/root/git/"
    if [ ! -d $str_dir ]; then
        mkdir -p $str_dir
    fi
    # LIST OF GITHUB REPOS
    declare -a arr_repo=(
    # NOTE: update here!
    #"username/reponame"
    "foundObjects/zram-swap"
    "pyllyukko/user.js"
    "StevenBlack/hosts"
    )
    # LOOP THRU LIST
    int_repo=${#arr_repo[@]}
    for (( int_index=0; int_index<$int_repo; int_index++ )); do
        # RESET WORKING DIRECTORY
        cd ~/                                                   # reset working dir
        str_repo=${arr_repo[$int_index]}
        str_user=$(echo $str_repo | cut -d "/" -f1)
        # CREATE FOLDER
        if [ ! -d $str_dir$str_user ]; then
            mkdir -p $str_dir$str_user
        fi
        # UPDATE LOCAL REPO
        if [ -e $str_dir$str_repo ]; then
            cd $str_dir$str_repo
            git pull https://github.com/$str_repo
        else
            cd $str_dir$str_user
            git clone https://github.com/$str_repo
        fi
    done
    echo "Git: End."
}

function 06_GitScripts {
    echo "GitScripts: Start."
    # StevenBlack/hosts #
    str_file="/etc/hosts"
    if [ -d $str_file'_old' ]; then
        sudo cp $str_file $str_file'_old' 
    else
        sudo cp $str_file'_old' $str_file
    fi
    #echo $'\n#' >> $str_file
    #cat /root/git/StevenBlack/hosts/hosts >> $str_file
    #
    # pyllyukko/user.js #
    cd /root/git/pyllyukko/user.js/
    make debian_locked.js
    str_file="/etc/firefox-esr/firefox-esr.js"
    if [ -d $str_file'_old' ]; then
        cp $str_file $str_file'_old' 
    fi
    cp /root/git/pyllyukko/user.js/debian_locked.js $str_file
    #ln -s /root/git/pyllyukko/user.js/debian_locked.js /etc/firefox-esr/firefox-esr.js     # NOTE: unused
    #
    # foundObjects/zram-swap #
    cd /root/git/foundObjects/zram-swap/
    sudo sh install.sh
    #
    echo "GitScripts: End."
}

## METHODS end ##

## NOTES ##

# TODO: either allow user to select each function to run, or have function check for existing changes and skip?

## MAIN start ##

echo "Script: Start."

00_Prompt           # works
#01A_Dependencies    # works
01B_Dependencies    # works
#02_Systemctl        # works
#03_SSH              # works
#04_UFW              # works
#05_Git              # works
#06_GitScripts       # works
#07_input_vfio   # user input here will affect relevant info later on...
#08_GRUB
#09_Xorg
#10_VFIO
#11_Libvirt
#99_CRONTAB
echo "Script: End."
exit 0

## MAIN end ##
