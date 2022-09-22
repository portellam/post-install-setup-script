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
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'."
            exit 1
        fi
    }

# systemd #
    function AppendToSystemd
    {
        echo -en "Appending files to Systemd... "

        # parameters #
        str_dir1=$(find . -name files | uniq | head -n1 | cut -d '.' -f2)
        cd '.'$str_dir1

        if [[ $(echo $(pwd)) == *"$str_dir1"* ]]; then

            # parameters #
            str_pattern=".service"
            declare -a arr1=($(ls | grep *".service") )

            for str_inFile1 in ${arr1[@]}; do

                # parameters #
                declare -i int_rem=${#str_pattern}
                int_rem=$((int_rem * -1))
                str_line1=${str_inFile1::int_rem}
                str_inFile2=$(find . | grep "$str_line1" | grep -Ev *".service" | uniq | head -n1)
                str_inFile2=$(echo $str_inFile2 | cut -d '/' -f2)
                str_outFile1="/etc/systemd/system/$str_inFile1"

                cp $str_inFile1 $str_outFile1
                chown root $str_outFile1
                chmod +x $str_outFile1

                if [[ -e $str_inFile2 ]]; then
                    str_outFile2="/usr/sbin/$str_inFile2"

                    if [[ -z $str_outFile2 ]]; then
                        cp $str_inFile2 $str_outFile2
                        chown root $str_outFile2
                        chmod +x $str_outFile2
                    fi
                fi

                str_outFile2=""
            done
        fi

        echo -e "Complete."
    }

# crontab #
    function AppendCron
    {
        # parameters #

        # list of packages that have cron files (see below) #
        # NOTE: may change depend on content of cron files (ex: simple, common commands that are not from given specific packages, i.e "cp" or "rm")
        # NOTE: update here!
        declare -a arr_requiredPackages=(
            "flatpak"
            "ntpdate"
            "rsync"
            "snap"
            "unattended-upgrades"
            )

        str_outDir1="/etc/cron.d/"
        str_dir1=$(find .. -name files | uniq | head -n1)"/"
        # cd $str_dir1


        # how do i get the file name after the last delimiter "/" ? check other repos or check for pattern regex
        if [[ -e $(find .. -wholename ${str_dir1}*-cron | uniq) ]]; then
            echo -e "Appending cron entries..."

            # # list of cron files #
            # declare -a arr1=$(find . -wholename ${str_dir1}*-cron | uniq | cut -d '/' -f2)

            # for str_line1 in $arr1; do

            #     # update parameters #
            #     str_input1=""

            #     ReadInput "Append '$str_line1'?"
            #     echo

            #     if [[ $str_input1 == "Y" ]]; then

            #         # parse list of packages that have cron files #
            #         for str_line2 in $arr_requiredPackages; do

            #             # match given cron file, append only if package exists in system #
            #             case $str_line1 in

            #                 *"$str_line2"*)
            #                     if [[ $(command -v $str_line2) == "/usr/bin/$str_line2" ]]; then
            #                         cp ${str_dir1}$str_line1 ${str_outDir1}${str_line1}
            #                         #echo -e "Appended file '$str_line1'."

            #                     else
            #                         echo -e "WARNING: Missing required package '$str_line2'. Skipping..."
            #                     fi
            #                     ;;

            #                 *)
            #                     echo;;
            #             esac
            #         done
            #     fi
            # done

            echo -e "Review changes made. "

        else
            echo -e "WARNING: Missing files. Skipping..."
        fi
    }

    function EditCrontab
    {
        str_file1="/var/spool/cron/crontabs/root"      # set working file
        declare -a arr_output1=()

        # backup system file #
        str_file1="/etc/ssh/ssh_config"
        str_oldFile1=${str_file1}"_old"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_oldFile1

        else
            touch $str_file1
        fi

        echo -en "Editing crontab.\nEnter your preferred ntp server (default: time.nist.gov): "
        read str_input1

        if [[ -z $str_input1 ]]; then
            str_input1="time.nist.gov";     # default value, change here!
        fi

        # append to output #
        if [[ $(command -v ntpdate) != "/usr/bin/ntpdate" ]]; then
            arr_output1+=(
                ""
                "# ntp #"
                "# update every 15 min"
                "0,15,30,45 * * * * ntpdate -s $str_input1"
            )
        fi

        # append to output #
        if [[ $(command -v unattended-upgrade) != "/usr/bin/unattended-upgrade"* ]]; then
            str_line1="#"

        else
            str_line1=""
        fi

        # append to output #
        arr_output1+=(
            ""
            "# apt #    # NOTE: better to use 'unattended-upgrades'"
            "# clean, update every 8 hours"
            "${str_line1}0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y"
            "# clean, update, autoremove every 8 hours"
            "#0 0,8,16 * * * apt clean && apt update && apt full-upgrade -y && apt autoremove -y"
        )

        # append to output #
        if [[ $(command -v flatpak) == "/usr/bin/flatpak" ]]; then
            arr_output1+=(
                ""
                "# flatpak #"
                " update every 8 hours"
                "0 0,8,16 * * * flatpak update -y"
            )
        fi

        # append to output #
        if [[ $(command -v snap) == "/usr/bin/snap" ]]; then
            arr_output1+=(
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
        while [[ $int_count -le 3 ]]; do

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
        str_oldFile1=$str_file1"_old"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # backup system file #
        str_file1="/etc/ssh/sshd_config"
        str_oldFile1=$str_file1"_old"

        if [ -e $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # append to output #
        str_output1+="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"

        echo -e $str_output1 >> $str_file1

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
    str_sshAlt=""

    # NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    # call functions #
    CheckIfUserIsRoot
    AppendToSystemd
    AppendCron
    # EditCrontab
    # EditSSH
    # EditFirewall

    IFS=$SAVEIFS        # reset IFS
    echo -e "Exiting."
    exit 0