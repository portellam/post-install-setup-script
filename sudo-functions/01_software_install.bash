#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

echo -en "\n$0: WARNING: If System Update is prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a\n$0: Updating system."
sudo apt clean
sudo apt update

# input variable
if [[ $1 == "Y"* ]]; then
    sudo apt full-upgrade -y
    sudo apt autoremove -y
else
    sudo apt full-upgrade
    sudo apt autoremove
fi
#

## install alternative software repos ##

# Qt DE (kde-plasma, LXQT)
str_aptCheck=$(apt list --installed plasma-desktop lxqt)
if [[ $str_aptCheck == *"installed"* ]]; then sudo apt install -y plasma-discover-backend-flatpak; fi

# GNOME DE (gnome, XFCE)
str_aptCheck=$(apt list --installed gnome xfwm4)
if [[ $str_aptCheck == *"installed"* ]]; then sudo apt install -y gnome-software-plugin-flatpak; fi

sudo apt install -y flatpak snapd
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
##

## apps ##      # NOTE: update here! ##
# organize by software type/group
# add debian-edu, minus the wallpaper
# add kali?

str_apt_dev="vscodium "
str_apt_drivers="steam-devices "
str_apt_driversVGA="nvidia-detect xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-cirrus xserver-xorg-video-fbdev xserver-xorg-video-glide xserver-xorg-video-intel xserver-xorg-video-ivtv-dbg xserver-xorg-video-ivtv xserver-xorg-video-mach64 xserver-xorg-video-mga xserver-xorg-video-neomagic xserver-xorg-video-nouveau xserver-xorg-video-openchrome xserver-xorg-video-qxl/ xserver-xorg-video-r128 xserver-xorg-video-radeon xserver-xorg-video-savage xserver-xorg-video-siliconmotion xserver-xorg-video-sisusb xserver-xorg-video-tdfx xserver-xorg-video-trident xserver-xorg-video-vesa xserver-xorg-video-vmware "
str_apt_internet="firefox-esr filezilla "
str_apt_media="vlc "
str_apt_office="libreoffice "
str_apt_security="fail2ban gufw ssh ufw "
str_apt_suites="debian-edu "
str_apt_tools="apcupsd bleachbit cockpit curl flashrom git grub-customizer java-common lm-sensors neofetch python3 qemu rtl-sdr synaptic unzip virt-manager wget wine youtube-dl zram-tools "
str_apt_games=""

str_flatpak_all="com.adobe.Flash-Player-Projector com.calibre_ebook.calibre com.makemkv.MakeMKV com.obsproject.Studio com.poweriso.PowerISO com.stremio.Stremio com.valvesoftware.Steam com.valvesoftware.SteamLink com.visualstudio.code com.vscodium.codium fr.handbrake.ghb io.github.Hexchat io.gitlab.librewolf-community nz.mega.MEGAsync org.bunkus.mkvtoolnix-gui org.filezillaproject.Filezilla org.freedesktop.LinuxAudio.Plugins.TAP org.freedesktop.LinuxAudio.Plugins.swh org.freedesktop.Platform org.freedesktop.Platform.Compat.i386 org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL32.nvidia-460-91-03 org.freedesktop.Platform.VAAPI.Intel.i386 org.freedesktop.Platform.ffmpeg-full org.freedesktop.Platform.openh264 org.freedesktop.Sdk org.getmonero.Monero org.gnome.Platform org.gtk.Gtk3theme.Breeze org.kde.KStyle.Adwaita org.kde.Platform org.kde.digikam org.kde.kdenlive org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.Thunderbird org.openshot.OpenShot org.videolan.VLC org.videolan.VLC.Plugin.makemkv org.libretro.RetroArch "
##

str_yes=""
if [[ $1 == "Y"* ]]; then str_yes="-y "; fi

echo -e "$0: Install selected Development apps?"
sudo apt install $str_yes$str_app_dev
echo -e "$0: Install selected drivers?"
sudo apt install $str_yes$str_app_drivers
echo -e "$0: Install selected VGA drivers?"
sudo apt install $str_yes$str_app_driversVGA
echo -e "$0: Install selected Internet/Network apps?"
sudo apt install $str_yes$str_app_internet
echo -e "$0: Install selected Media apps?"
sudo apt install $str_yes$str_app_media
echo -e "$0: Install selected Office apps?"
sudo apt install $str_yes$str_app_office
echo -e "$0: Install selected app suites?"
sudo apt install $str_yes$str_app_office
echo -e "$0: Install selected tool apps?"
sudo apt install $str_yes$str_app_tools

echo -e "$0: Install selected Flatpak apps?"
sudo flatpak install flathub $str_yes$str_flatpakAdd

IFS=$SAVEIFS        # reset IFS
echo "$0: Exiting."
exit 0