#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# NOTE: for every use of a cli command i.e cfw or ssh, check if package exists, warn user if it doesn't

local_int_count=0   # reset counter
    
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

        if [ "$str_sshAlt" -gt 0 ]; then break; fi

    else echo "SSH: Invalid input. First parameter must be an integer."; fi
        
    ((int_count++)) 
done
    
local_str_file1="/etc/ssh/ssh_config"
    
# check if backup exists #
if [ ! -d $local_str_file1'_old' ]; then
    cp $local_str_file1 $local_str_file1'_old' 
else
    cp $local_str_file1'_old' $local_str_file1
fi
#

echo $'\n#\nPort '$str_sshAlt >> $local_str_file1
local_str_file1="/etc/ssh/sshd_config"
    
if [ ! -d $local_str_file1'_old' ]; then
    cp $local_str_file1 $local_str_file1'_old' 
else
    cp $local_str_file1'_old' $local_str_file1
fi
#
    
# write to file
echo $'\n#\nPort '$str_sshAlt >> $local_str_file1
cat << 'EOF' >> $local_str_file1
LoginGraceTime 1m
PermitRootLogin prohibit-password
MaxAuthTries 6
MaxSessions 2
EOF
#

systemctl restart ssh sshd  # restart services

if [[ $str_sshAlt -eq 22 ]]; then
    sudo ufw limit from 192.168.1.0/24 to any port 22 proto tcp    
else
    sudo ufw deny ssh
    sudo ufw limit from 192.168.0.0/16 to any port $str_sshAlt proto tcp
fi
    
# NOTE: changes here
sudo ufw allow DNS
sudo ufw allow VNC
sudo ufw enable
sudo ufw reload


IFS=$SAVEIFS                # reset IFS
echo "$0: Exiting."
exit 0