#!/bin/bash sh

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ `whoami` != "root" ]]; then
            str_file1=`echo ${0##/*}`
            str_file1=`echo $str_file1 | cut -d '/' -f2`
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'."
            exit 0
        fi
    }

# crontab #
    function EditCrontab
    {
        str_file1="/var/spool/cron/crontabs/root"      # set working file
        declare -a arr_file1

        # backup system file #
        str_file1="/etc/ssh/ssh_config"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_file1'_old'
        fi

        echo -en "$0: Editing crontab.\n$0: Enter your preferred ntp server (default: time.nist.gov): "
        read str_input1

        if [[ -z $str_input1 ]]; then
            str_input1="time.nist.gov";     # default value, change here!
        fi

        str_aptCheck=`apt list --installed ntpdate`

        if [[ $str_aptCheck == *"installed"* ]]; then
            arr_file1+=(
                ""
                "# ntp #"
                "# update every 15 min"
                "0,15,30,45 * * * * ntpdate -s $str_input1"
            )
        fi

        str_aptCheck=`apt list --installed unattended-upgrades`

        if [[ $str_aptCheck == *"installed"* ]]; then str_line1="#"
        else str_line1=""; fi
        arr_file1+=(
            ""
            "# apt #    # NOTE: better to use 'unattended-upgrades'"
            "# clean, update every 8 hours"
            "${str_line1}0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y"
            "# clean, update, autoremove every 8 hours"
            "#0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y && apt autoremove -y"
        )

        str_aptCheck=`apt list --installed flatpak`

        if [[ $str_aptCheck == *"installed"* ]]; then
            arr_file1+=(
                ""
                "# flatpak #"
                " update every 8 hours"
                "0 0,8,16 * * * flatpak update -y"
            )
        fi

        str_aptCheck=`apt list --installed snapd`

        if [[ $str_aptCheck == *"installed"* ]]; then
            arr_file1+=(
                ""
                "# snap #"
                "# update every 8 hours"
                "0 0,8,16 * * * snap update -y"
            )
        fi
    }

# SSH #
    function EditSSH
    {
        # parameters #
        declare -i int_count=0  # reset counter
        str_output1=""          # reset output

        # prompt #
        while true; do

            # default input #
            if [ $int_count -gt 2 ]; then
                str_sshAlt=22
                echo -en "Exceeded max attempts! "

            # read input #
            else
                echo -e "Enter a new IP Port number for SSH (leave blank for default):"
                read str_sshAlt
            fi

            # match string with valid integer #
            if [ "$str_sshAlt" -eq "$str_sshAlt" ] 2> /dev/null; then

                # parameters #
                declare -i int_number="$str_sshAlt"

                if [[ $int_number -gt 0 && $int_number -lt 65536 ]]; then
                    if [[ $int_number -gt 1000 ]]; then
                        if [[ $int_number == 22 ]]; then
                            echo -e "Default value."

                        # append to output #
                        else
                            str_output1+="\n#\nPort $str_sshAlt"
                        fi

                    else
                        echo -e "Invalid selection. Available port range: 1000-65535"
                    fi
                else
                    echo -e "Invalid integer. Valid port range: 1-65535."
                fi

            # false match string with valid integer #
            else
                echo -e "Invalid input."
            fi

            ((int_count++))   # counter
        done

        # backup system file #
        str_file1="/etc/ssh/ssh_config"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_file1'_old'
        fi

        # backup system file #
        str_file1="/etc/ssh/sshd_config"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_file1'_old'
        fi

        # append to output #
        str_output1+="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"

        echo -e $str_output1 >> $strfile1

        systemctl restart ssh sshd  # restart services
    }

# UFW #
    function EditFirewall
    {
        if [[ $str_sshAlt == "" ]]; then
            sudo ufw limit from 192.168.0.0/16 to any port 22 proto tcp

        else
            sudo ufw deny ssh
            sudo ufw limit from 192.168.0.0/16 to any port $str_sshAlt proto tcp
        fi

        # NOTE: change here!
        sudo ufw allow DNS
        sudo ufw allow VNC
        sudo ufw allow from 192.168.0.0/16 to any port 2049                 # NFS
        sudo ufw allow from 192.168.0.0/16 to any port 3389                 # RDP
        sudo ufw allow from 192.168.0.0/16 to any port 9090 proto tcp       # cockpit
        sudo ufw allow from 192.168.0.0/16 to any port 137:138 proto udp    # CIFS
        sudo ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp    # CIFS

        # save changes #
        sudo ufw enable
        sudo ufw reload
    }

# main #

    # parameters #
    bool_exit=false
    str_sshAlt=""

    while [[ $bool_exit == false ]]; do

        # NOTE: necessary for newline preservation in arrays and files #
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char

        # call functions #
        CheckIfUserIsRoot
        EditCrontab
        EditSSH
        EditFirewall

        echo -e "\nWARNING: If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
        break
    done

    if [[ $bool_exit == true ]]; then
        echo -en "WARNING: Setup cannot continue. "
    fi

    IFS=$SAVEIFS        # reset IFS
    echo "Exiting."
    exit 0