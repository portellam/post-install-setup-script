#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

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

# SSH #
if [[ $str_sshAlt -eq 22 ]]; then
    sudo ufw limit from 192.168.0.0/16 to any port 22 proto tcp    
else
    sudo ufw deny ssh
    sudo ufw limit from 192.168.0.0/16 to any port $str_sshAlt proto tcp
fi
#
    
# NOTE: changes here
sudo ufw allow DNS
sudo ufw allow VNC
sudo ufw allow from 192.168.0.0/16 to any port 2049                 # NFS   
sudo ufw allow from 192.168.0.0/16 to any port 3389                 # RDP
sudo ufw allow from 192.168.0.0/16 to any port 9090 proto tcp       # cockpit
sudo ufw allow from 192.168.0.0/16 to any port 137:138 proto udp    # CIFS
sudo ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp    # CIFS
#

sudo ufw enable
sudo ufw reload
IFS=$SAVEIFS                # reset IFS
echo -e "$0: Exiting."
exit 0