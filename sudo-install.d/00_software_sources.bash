#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# check if sudo/root #
    function CheckIfUserIsRoot
    {
        if [[ `whoami` != "root" ]]; then
            str_file1=`echo ${0##/*}`
            str_file1=`echo $str_file1 | cut -d '/' -f2`
            echo -e "WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file1'\n\tor\n\t'su' and 'bash $str_file1'. Exiting."
            exit 0
        fi
    }

# procede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {

        # parameters #
        str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
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

                str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
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

# check if in correct dir #
    function CheckForCorrectWorkingDir
    {
        # parameters #
        str_pwd=`pwd`

        if [[ `echo ${str_pwd##*/}` != "install.d" ]]; then
            if [[ -e `find . -name install.d` ]]; then
                cd `find . -name install.d`

            else
                echo -e "WARNING: Script cannot locate the correct working directory."
            fi
        fi
    }

# check linux distro #
    function CheckCurrentDistro
    {
        echo -e "Linux distribution found: `lsb_release -i -s`"

        # Debian/Ubuntu
        if [[ `lsb_release -i -s | grep -Ei "debian|ubuntu"` ]]; then
            echo -e "Linux distribution is compatible with setup. Continuing."

        else
            echo -e "Linux distribution not compatible with setup. Exiting."
            bool_exit=true
        fi
    }

# set software repositories #
    function ModifyDebianRepos
    {

        # parameters #
        str_releaseName=`lsb_release -sc`
        str_releaseVer=`lsb_release -sr`
        str_file1="/etc/apt/sources.list"
        str_oldFile1="${str_file1}_old"
        str_newFile1="${str_file1}_new"

        # create backup or restore from backup #
        if [ -z $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # prompt user to change apt dependencies #
        while true; do

            # prompt for non-free sources #
            str_input1=""
            ReadInput "Include non-free sources?"

            case $str_input1 in
                    "Y")
                        str_sources="non-free contrib";;

                    *)
                        str_sources="contrib";;
                esac


            # manual prompt #
            if [[ $int_count -ge 3 ]]; then
                echo -e "Exceeded max attempts!"
                str_input2=stable     # default input     # NOTE: change here

            else
                echo -e "Repositories: Enter one valid option or none for default (Current branch: $str_releaseName)."
                echo -e "\tWARNING: It is NOT possible to revert from a Non-stable branch back to a Stable or $str_releaseName branch."
                echo -e "\tRelease branches:"
                echo -e "\t\t'stable'\t== '$str_releaseName'"
                echo -e "\t\t'testing'\t*more recent updates, slightly less stability"
                echo -e "\t\t'unstable'\t*most recent updates, least stability. NOT recommended."
                echo -e "\t\t'backports'\t== '$str_releaseName-backports'\t*optionally receive more recent updates."
                echo -en "\tEnter option: "

                read str_input2
                str_input2=$(echo $str_input2 | tr '[:upper:]' '[:lower:]')   # string to lowercase
            fi

            # exit with no changes #
            if [[ $str_input2 == "stable" ]]; then
                echo -e "No changes. Skipping."
                break
            fi

            # apt sources
            declare -a arr_sources=(
                "# debian $str_input2"
                "# See https://wiki.debian.org/SourcesList for more information."
                "deb http://deb.debian.org/debian/ $str_input2 main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_input2 main $str_sources"
                $'\n'
                "deb http://deb.debian.org/debian/ $str_input2-updates main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_input2-updates main $str_sources"
                $'\n'
                "deb http://security.debian.org/debian-security/ $str_input2-security main $str_sources"
                "deb-src http://security.debian.org/debian-security/ $str_input2-security main $str_sources"
                "#"
            )

            # copy lines from original to temp file as comments #
            if [[ -e $str_newFile1 ]]; then
                rm $str_newFile1
            fi

            touch $str_newFile1

            while read str_line1; do
                if [[ $str_line1 != "#"* ]]; then
                    str_line1="#$str_line1"
                fi

                echo $str_line1 >> $str_newFile1
            done < $str_file1

            if [[ -e $str_file1 ]]; then
                rm $str_file1
            fi

            mv $str_newFile1 $str_file1

            # delete optional sources file, if it exists #
            if [ -e '/etc/apt/sources.list.d/'$str_input2'.list' ]; then
                rm '/etc/apt/sources.list.d/'$str_input2'.list'
            fi

            # input prompt #
            case $str_input2 in

                # valid choices #
                "testing"|"unstable")

                    echo -e "\tSelected \"$str_input2\"."

                    # write to file #
                    int_line1=${#arr_sources[@]}

                    for (( int_i=0; int_i<$int_line1; int_i++ )); do
                        str_line1=${arr_sources[$int_i]}
                        echo $str_line1 >> '/etc/apt/sources.list.d/'$str_input2'.list'
                    done

                    break;;

                # current branch with backports
                "backports")

                    echo -e "\tSelected \"$str_input2\"."

                    # apt sources
                    declare -a arr_sources=(
        $'\n'
        "# debian $str_releaseVer/$str_releaseName"
        "# See https://wiki.debian.org/SourcesList for more information."
        "deb http://deb.debian.org/debian/ $str_releaseName main $str_sources"
        "deb-src http://deb.debian.org/debian/ $str_releaseName main $str_sources"
        $'\n'
        "deb http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
        "deb-src http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
        $'\n'
        "deb http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
        "deb-src http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
        "#"
        "# debian $str_releaseVer/$str_releaseName $str_input2"
        "deb http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
        "deb-src http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
        "#"
        )
                    # write to file #
                    int_line1=${#arr_sources[@]}

                    for (( int_i=0; int_i<$int_line1; int_i++ )); do
                        str_line1=${arr_sources[$int_i]}
                        echo $str_line1 >> '/etc/apt/sources.list.d/'$str_input2'.list'
                    done

                    break;;

                # invalid selection #
                *)
                    echo -e "Invalid input."

            esac
            ((int_count++))     # counter
        done

        if [[ -e $str_newFile1 ]]; then
                rm $str_newFile1
        fi

        sudo apt clean
        sudo apt update
        sudo apt full-upgrade

        # clean up #
        # sudo apt autoremove -y
    }

# main #

    # parameters #
    bool_exit=false

    while [[ $bool_exit == false ]]; do

        # NOTE: necessary for newline preservation in arrays and files #
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char

        # call functions #
        CheckIfUserIsRoot
        CheckForCorrectWorkingDir
        CheckCurrentDistro
        ModifyDebianRepos

        echo -e "\nWARNING: If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
        break
    done

    if [[ $bool_exit == true ]]; then
        echo -en "WARNING: Setup cannot continue. "
    fi

    IFS=$SAVEIFS        # reset IFS
    echo "Exiting."
    exit 0