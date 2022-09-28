#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ $(whoami) != "root" ]]; then
            str_file1=$(echo ${0##/*})
            str_file1=$(echo ${str_file1} | cut -d '/' -f2)
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'bash ${str_file1}'\n\tor\n\t'su' and 'bash ${str_file1}'."
            exit 1
        fi
    }

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=$(echo ${str_input1} | tr '[:lower:]' '[:upper:]')
        str_input1=${str_input1:0:1}
        declare -i int_count=0      # reset counter

        while true; do

            # manual prompt #
            if [[ ${int_count} -ge 3 ]]; then
                echo -en "Exceeded max attempts. "
                str_input1="N"                    # default input     # NOTE: update here!

            else
                echo -en "\t${1} [Y/n]: "
                read str_input1

                str_input1=$(echo ${str_input1} | tr '[:lower:]' '[:upper:]')
                str_input1=${str_input1:0:1}
            fi

            case ${str_input1} in
                "Y"|"N")
                    break;;

                *)
                    echo -en "\tInvalid input. ";;
            esac

            ((int_count++))         # increment counter
        done
    }

# systemd #
    function AppendServices
    {
        echo -e "Appending files to Systemd..."

        # parameters #
        str_dir1="$(pwd)/$( basename $(find . -name services | uniq | head -n1 ))"
        str_pattern=".service"
        cd ${str_dir1}

        declare -a arr1=( $( ls | uniq | grep -Ev ${str_pattern} ))

        for str_inFile1 in ${arr1[@]}; do
            str_outFile1="/usr/sbin/${str_inFile1}"
            cp ${str_inFile1} ${str_outFile1}
            chown root ${str_outFile1}
            chmod +x ${str_outFile1}
        done

        declare -a arr1=( $( ls | uniq | grep ${str_pattern} ))

        for str_inFile1 in ${arr1[@]}; do
            declare -i int_fileNameLength=$((${#str_inFile1} - ${#str_pattern}))
            str_outFile1="/etc/systemd/system/${str_inFile1}"

            cp ${str_dir1}"/"${str_inFile1} ${str_outFile1}
            chown root ${str_outFile1}
            chmod +x ${str_outFile1}

            systemctl daemon-reload
            str_input1=""
            ReadInput "Enable/disable '${str_inFile1}'?"

            case ${str_input1} in
                "Y")
                    systemctl enable ${str_inFile1};;

                "N")
                    systemctl disable ${str_inFile1};;
            esac
        done

        systemctl daemon-reload
        echo -e "Appending files to Systemd... Complete."
    }

# crontab #
    function AppendCron
    {
        # parameters #
        declare -a arr1=()
        str_outDir1="/etc/cron.d/"
        str_dir1=$(find .. -name files | uniq | head -n1)"/"

        # list of packages that have cron files (see below) #
        # NOTE: may change depend on content of cron files (ex: simple, common commands that are not from given specific packages, i.e "cp" or "rm")
        # NOTE: update here!
        declare -a arr_requiredPackages=(
            "flatpak"
            "ntpdate"
            "rsync"
            "snap"
        )

        if [[ $(command -v unattended-upgrades) == "" ]]; then
            arr_requiredPackages+=("apt")
        fi

        if [[ ${str_dir1} != "" ]]; then
            cd ${str_dir1}

            # list of cron files #
            arr1=$(ls *-cron)
        fi

        # how do i get the file name after the last delimiter "/" ? check other repos or check for pattern regex
        if [[ ${#arr1[@]} -gt 0 ]]; then
            echo -e "Appending cron entries..."

            for str_line1 in ${arr1}; do

                # update parameters #
                str_input1=""

                ReadInput "Append '${str_line1}'?"
                echo

                if [[ ${str_input1} == "Y" ]]; then

                    # parse list of packages that have cron files #
                    for str_line2 in ${arr_requiredPackages[@]}; do

                        # match given cron file, append only if package exists in system #
                        if [[ ${str_line1} == *"${str_line2}"* ]]; then
                            if [[ $(command -v ${str_line2}) != "" ]]; then
                                cp ${str_dir1}${str_line1} ${str_outDir1}${str_line1}
                                # echo -e "Appended file '${str_line1}'."

                            else
                                echo -e "WARNING: Missing required package '${str_line2}'. Skipping..."
                            fi
                        fi
                    done
                fi
            done

            echo -e "Review changes made. "

        else
            echo -e "WARNING: Missing files. Skipping..."
        fi

        # restart service #
        systemctl restart cron
    }

# SSH #
    function ModifySSH
    {
        # parameters #
        str_input1=""
        ReadInput "Modify SSH?"

        if [[ $str_input1 = "Y" ]]; then
            if [[ $( command -v ssh ) != "" ]]; then
                declare -i int_count=0
                str_output1=""

                # prompt #
                while [[ ${int_count} -le 3 ]]; do

                    # default input #
                    if [ ${int_count} -gt 2 ]; then
                        str_sshAlt=22
                        echo -en "Exceeded max attempts! "

                    # read input #
                    else
                        echo -en "\tEnter a new IP Port number for SSH (leave blank for default): "
                        read str_sshAlt
                    fi

                    # match string with valid integer #
                    if [ "${str_sshAlt}" -eq "$(( ${str_sshAlt} ))" ] 2> /dev/null; then
                        declare -i int_result="${str_sshAlt}"

                        if [[ ${int_result} -gt 0 && ${int_result} -lt 65536 ]]; then
                            if [[ ${int_result} -gt 1000 ]]; then
                                if [[ ${int_result} == 22 ]]; then
                                    echo -e "Default value."

                                # append to output #
                                else
                                    str_output1+="\n#\nPort ${str_sshAlt}"
                                    break
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

                    ((int_count++))
                done

                # backup and write to file #
                    str_file1="/etc/ssh/ssh_config"
                    str_oldFile1=${str_file1}"_old"

                    if [ -e ${str_file1} ]; then
                        cp ${str_file1} ${str_oldFile1}
                    fi

                    echo -e ${str_output} >> ${str_file1}

                # backup and write to file #
                    str_output1+="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"    # append to output
                    str_file1="/etc/ssh/ssh_config"
                    str_oldFile1=${str_file1}"_old"

                    if [ -e ${str_file1} ]; then
                        cp ${str_file1} ${str_oldFile1}
                    fi

                    echo -e ${str_output1} >> ${str_file1}

                systemctl restart ssh sshd  # restart services

            else
                echo -e "WARNING: SSH not installed! Skipping..."
            fi
        fi

        echo
    }

# security #
    function ModifySecurity
    {
        echo -e "Configuring system security..."

        # parameters #
        bool_runOperationIfFileExists=false
        str_input1=""
        # str_packagesToRemove="atftpd nis rsh-redone-server rsh-server telnetd tftpd tftpd-hpa xinetd yp-tools"
        str_services="acpupsd cockpit fail2ban ssh ufw"     # include services to enable OR disable: cockpit, ssh, some/all packages installed that are a security-risk or benefit.

        # echo -e "Remove given apt packages?"
        # apt remove ${str_packagesToRemove}

        str_input1=""
        ReadInput "Disable given device interfaces (for storage devices only): USB, Firewire, Thunderbolt?"

        case ${str_input1} in
            "Y")
                echo 'install usb-storage /bin/true' > /etc/modprobe.d/disable-usb-storage.conf
                echo "blacklist firewire-core" > /etc/modprobe.d/disable-firewire.conf
                echo "blacklist thunderbolt" >> /etc/modprobe.d/disable-thunderbolt.conf
                update-initramfs -u -k all
                ;;

            "N")
                if [[ -e /etc/modprobe.d/disable-usb-storage.conf ]]; then
                    rm /etc/modprobe.d/disable-usb-storage.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ -e /etc/modprobe.d/disable-firewire.conf ]]; then
                    rm /etc/modprobe.d/disable-firewire.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ -e /etc/modprobe.d/disable-thunderbolt.conf ]]; then
                    rm /etc/modprobe.d/disable-thunderbolt.conf
                    bool_runOperationIfFileExists=true
                fi

                if [[ $bool_runOperationIfFileExists == true ]]; then
                    update-initramfs -u -k all
                fi
                ;;
        esac

        echo

        str_dir1=$(find .. -name files | uniq | head -n1)"/"

        if [[ ${str_dir1} != "" ]]; then
            cd ${str_dir1}
            str_inFile1="./sysctl.conf"
            str_file1="/etc/sysctl.conf"
            str_oldFile1="/etc/sysctl.conf_old"
        else
            str_inFile1=""
        fi

        if [[ -e ${str_inFile1} ]]; then
            str_input1=""
            ReadInput "Setup /etc/sysctl.conf with defaults?"

            if [[ ${str_input1} == "Y" && ${str_inFile1} != "" ]]; then
                cp ${str_file1} ${str_oldFile1}
                cat ${str_inFile1} >> ${str_file1}
            fi

        else
            echo -e "WARNING: '/etc/sysctl.conf' missing. Skipping..."
        fi

        echo

        str_input1=""
        ReadInput "Setup firewall with UFW?"

        if [[ ${str_input1} == "Y" ]]; then
            if [[ $(command -v ufw) != "" ]]; then
                # NOTE: change here!
                # basic #
                ufw reset
                ufw default allow outgoing
                ufw default deny incoming

                # NOTE: default LAN subnets may be 192.168.1.0/24

                # secure-shell on local lan #
                if [[ $(command -v ssh) != "" ]]; then
                    if [[ ${str_sshAlt} != "" ]]; then
                        ufw deny ssh comment 'deny default ssh'
                        ufw limit from 192.168.0.0/16 to any port ${str_sshAlt} proto tcp comment 'ssh'

                    else
                        ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh'
                    fi

                    ufw deny ssh comment 'deny default ssh'
                fi

                # services a desktop uses #
                ufw allow DNS comment 'dns'
                ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server'
                ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server'

                ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server'
                ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server'
                ufw allow VNC comment 'VNC, local remote desktop server'

                # services a server may use #
                # ufw allow http comment 'HTTP, local Web server'
                # ufw allow https comment 'HTTPS, local Web server'

                # ufw allow 25 comment 'SMTPD, local mail server'
                # ufw allow 110 comment 'POP3, local mail server'
                # ufw allow 995 comment 'POP3S, local mail server'
                # ufw allow 1194/udp 'SMTPD, local VPN server'
                ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server'

                # save changes #
                ufw enable
                ufw reload

            else
                echo -e "WARNING: UFW is not installed. Skipping..."
            fi
        fi

        # edit hosts file here?
    }

# main #

    # parameters #
    str_sshAlt=""

    # NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=${IFS}   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    # call functions #
    CheckIfUserIsRoot
    AppendServices
    AppendCron
    ModifySSH $str_sshAlt
    ModifySecurity $str_sshAlt

    IFS=$SAVEIFS        # reset IFS
    echo -e "Exiting."
    exit 0