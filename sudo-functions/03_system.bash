#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

## crontab ##

local_str_file1="/var/spool/cron/crontabs/root"      # set working file
declare -a local_arr_file1
    
# create backup or restore from backup #
if [ ! -d $local_str_file1 ]; then
    cp $local_str_file1 $local_str_file1'_old'
else
    cp $local_str_file1'_old' $local_str_file1
fi
#

echo -en "$0: Editing crontab.\n$0: Enter your preferred ntp server (default: time.nist.gov): "
read local_str_input1
if [[ -z $local_str_input1 ]]; then local_str_input1="time.nist.gov"; fi

str_aptCheck=$(apt list --installed ntpdate)
if [[ $str_aptCheck == *"installed"* ]]; then
    local_arr_file1+=(
        ""
        "# ntp #"
        "# update every 15 min"
        "0,15,30,45 * * * * ntpdate -s $local_str_input1"
    )
fi

str_aptCheck=$(apt list --installed unattended-upgrades)
if [[ $str_aptCheck == *"installed"* ]]; then local_str_line1="#"
else local_str_line1=""; fi
local_arr_file1+=(
    ""
    "# apt #    # NOTE: better to use 'unattended-upgrades'"
    "# clean, update every 8 hours"
    "${local_str_line1}0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y"
    "# clean, update, autoremove every 8 hours"
    "#0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y && apt autoremove -y"
)

str_aptCheck=$(apt list --installed flatpak)
if [[ $str_aptCheck == *"installed"* ]]; then
    local_arr_file1+=(
        ""
        "# flatpak #"
        " update every 8 hours"
        "0 0,8,16 * * * flatpak update -y"
    )
fi

str_aptCheck=$(apt list --installed snapd)
if [[ $str_aptCheck == *"installed"* ]]; then
    local_arr_file1+=(
        ""
        "# snap #"
        "# update every 8 hours"
        "0 0,8,16 * * * snap update -y"
    )
fi
##

## SSH ##

local_int_count=0   # reset counter
    
while true; do

    if [ $local_int_count -gt 2 ]; then
        str_sshAlt=22
        echo -e "$0: Exceeded max attempts!\n$0: Value is set to default."
        break
    fi
        
    echo -e "$0: Enter a new IP Port number for SSH:"
    read str_sshAlt
        
    if [ "$str_sshAlt" -eq "$str_sshAlt" ] 2> /dev/null; then
        
        if [ "$str_sshAlt" -eq 22 ]; then   
            echo -e "$0: Value is set to default."
            break     
        fi
        if [ "$str_sshAlt" -gt 0 ]; then break; fi
    else echo -e "$0: Invalid input. First parameter must be an integer."; fi
        
    ((local_int_count++))   # counter
done
    
# SSH, check if backup exists #
local_str_file1="/etc/ssh/ssh_config"

if [ ! -d $local_str_file1'_old' ]; then cp $local_str_file1 $local_str_file1'_old' 
else cp $local_str_file1'_old' $local_str_file1; fi

echo $'\n#\nPort '$str_sshAlt >> $local_str_file1
#

# SSHD, check if backup exists #
local_str_file1="/etc/ssh/sshd_config"
    
if [ ! -d $local_str_file1'_old' ]; then cp $local_str_file1 $local_str_file1'_old' 
else cp $local_str_file1'_old' $local_str_file1; fi
    
echo $'\n#\nPort '$str_sshAlt >> $local_str_file1
cat << 'EOF' >> $local_str_file1
LoginGraceTime 1m
PermitRootLogin prohibit-password
MaxAuthTries 6
MaxSessions 2
EOF
#

systemctl restart ssh sshd  # restart services
##

## UFW ##
if [[ $str_sshAlt -eq 22 ]]; then
    sudo ufw limit from 192.168.0.0/16 to any port 22 proto tcp    
else
    sudo ufw deny ssh
    sudo ufw limit from 192.168.0.0/16 to any port $str_sshAlt proto tcp
fi
    
# NOTE: changes here
sudo ufw allow DNS
sudo ufw allow VNC
sudo ufw allow from 192.168.0.0/16 to any port 2049                 # NFS   
sudo ufw allow from 192.168.0.0/16 to any port 3389                 # RDP
sudo ufw allow from 192.168.0.0/16 to any port 9090 proto tcp       # cockpit
sudo ufw allow from 192.168.0.0/16 to any port 137:138 proto udp    # CIFS
sudo ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp    # CIFS

sudo ufw enable
sudo ufw reload
##

IFS=$SAVEIFS                # reset IFS
echo -e "$0: Exiting."
exit 0