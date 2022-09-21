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
            exit 0
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

# clone repos #
    function CloneGitRepos
    {
        echo "Cloning/Updating Git repos..."

        # parameters #
        str_dir1="/root/git/"

        if [[ -z $str_dir1 ]]; then
            sudo mkdir -p $str_dir1
        fi

        # here goes useful repos for system deployment
        # list of git repos
        # NOTE: update here!
        declare -a arr_repo=(

        #"username/reponame"
        "corna/me_cleaner"
        "dt-zero/me_cleaner"
        "foundObjects/zram-swap"
        "portellam/Auto-Xorg"
        "portellam/deploy-VFIO-setup"
        "pyllyukko/user.js"
        "StevenBlack/hosts"

        )

        # loop thru list
        for str_repo in ${arr_repo[@]}; do

            # reset working dir
            cd ~/

            str_userName=$(echo $str_repo | cut -d "/" -f1)

            # create folder #
            if [[ -z $str_dir1$str_userName ]]; then
                mkdir -p $str_dir1$str_userName
            fi

            # update local repo #
            if [[ -e $str_dir1$str_repo ]]; then
                cd $str_dir1$str_repo
                git pull https://github.com/$str_repo

            else

                ReadInput "Clone repo '$str_repo'?"

                if [[ $str_input1 == "Y" ]]; then
                    cd $str_dir1$str_userName
                    git clone https://github.com/$str_repo
                fi

            fi
        done
    }

# install from git repos #
    function InstallFromGitRepos
    {
        echo "Executing Git scripts..."

        # parameters #
        str_dir1="/root/git/"
        str_input1=""
        cd $str_dir1

        # prompt user to execute script or do so automatically #
        function ExecuteScript {
            str_input1=""
            ReadInput "Execute script '$str_repo'?"
        }

        # portellam/Auto-Xorg #
        str_repo="portellam/Auto-Xorg"

        if [[ -e $str_repo ]]; then
            ExecuteScript $str_repo

            if [[ $str_input1 == "Y" ]]; then
                cd $str_dir1$str_repo
                sudo bash ./installer.bash
                cd $str_dir1
            fi
        fi

        # StevenBlack/hosts #
        str_repo="StevenBlack/hosts"
        if [[ -e $str_repo ]]; then
            ExecuteScript $str_repo

            if [[ $str_input1 == "Y" ]]; then
                cd $str_dir1$str_repo
                str_file1="/etc/hosts"
                str_oldFile1=$str_file1'_old'

                # backup hosts #
                if [[ ! -e $str_oldFile1 ]]; then
                    if [[ -e $str_file1 ]]; then
                        sudo cp $str_file1 $str_oldFile1
                    fi

                else
                    sudo cp $str_oldFile1 $str_file1
                fi

                echo $'\n#' >> $str_file1
                cat hosts >> $str_file1
                cd $str_dir1
            fi
        fi

        # pyllyukko/user.js #
        str_repo="pyllyukko/user.js"

        if [[ -e $str_repo ]]; then
            ExecuteScript $str_repo

            if [[ $str_input1 == "Y" ]]; then
                cd $str_dir1$str_repo
                make debian_locked.js
                str_file1="/etc/firefox-esr/firefox-esr.js"

                # backup user.js #
                if [[ -e $str_file1'_old' ]]; then
                    sudo cp $str_file1 $str_file1'_old'
                fi

                cp debian_locked.js $str_file1
                #ln -s debian_locked.js /etc/firefox-esr/firefox-esr.js      # NOTE: unused
                cd $str_dir1
            fi
        fi

        # foundObjects/zram-swap #
        str_repo="foundObjects/zram-swap"

        if [[ -e $str_repo ]]; then
            ExecuteScript $str_repo

            if [[ $str_input1 == "Y" ]]; then
                cd $str_dir1$str_repo
                sudo sh ./install.sh
                cd $str_dir1
            fi
        fi
    }

# main #

    # parameters #
    declare -a arr_repo=()

    while true; do

        # NOTE: necessary for newline preservation in arrays and files #
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char

        # call functions #
        CheckIfUserIsRoot

        if [[ $(command -v git) == "/usr/bin/git" ]]; then
            CloneGitRepos
            InstallFromGitRepos

        else
            echo -e "WARNING: Git is not installed on this system. Exiting."
            exit 1
        fi

        echo -e "\nWARNING: If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
        break
    done

    IFS=$SAVEIFS        # reset IFS
    echo -e"Exiting."
    exit 0