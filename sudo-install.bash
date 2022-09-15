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

# check if in correct dir #
    function CheckForCorrectWorkingDir
    {
        # parameters #
        str_pwd=$(pwd)

        if [[ $(echo ${str_pwd##*/}) != "install.d" ]]; then
            if [[ -e $(find . -name install.d) ]]; then
                cd $(find . -name install.d)

            else
                echo -e "WARNING: Script cannot locate the correct working directory."
            fi
        fi
    }

# main #
    # parse and execute functions #

    # parameters #
    bool_exit=false
    str_dir1="sudo-install.d/"

    # call functions #
    CheckIfUserIsRoot
    CheckForCorrectWorkingDir

        while [[ $bool_exit == false ]]; do

            if [[ -z $(find . -name *$str_dir1*) ]]; then
                echo -e "Executing functions... Failed. Missing files."
                bool_exit=true

            else
                echo -e "Executing functions..."

                declare -a arr_dir1=$(ls $str_dir1 | sort -h)

                # call functions #
                for str_line1 in $arr_dir1; do

                    # update parameters #
                    str_input1=""

                    # execute sh/bash scripts in directory
                    if [[ $str_line1 == *".bash" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
                        ReadInput "Execute '$str_line1'?"
                        echo
                    fi

                    if [[ $str_input1 == "Y" && $str_line1 == *".bash" && $str_line1 != *".log" ]]; then
                        sudo bash $str_dir1$str_line1
                        echo
                    fi

                    if [[ $str_input1 == "Y" && $str_line1 == *".sh" && $str_line1 != *".log" ]]; then
                        sudo sh $str_dir1$str_line1
                        echo
                    fi
                done

                echo -en "Review changes made. "
            fi

        break
        done

    if [[ $bool_exit == true ]]; then
        echo -en "WARNING: Setup cannot continue. "
    fi

    IFS=$SAVEIFS        # reset IFS
    echo "Exiting."
    exit 0