#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# user input #
local_str_input1=""

function UserInput {
    declare -i local_int_count=0            # reset counter
    echo $local_str_input1
    while true; do
        # passthru input variable if it is valid #
        if [[ $1 == "Y"* || $1 == "y"* ]]; then
            local_str_input1=$1     # input variable
            break
        fi
        #
        # manual prompt #
        if [[ $local_int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts."
            local_str_input1="N"                     # default input     # NOTE: change here
        else                                        # manual prompt
            echo -en "$0: [Y/n]: "
            read local_str_input1
            # string to upper
            local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
            local_str_input1=${local_str_input1:0:1}
            #
        fi
        #
        case $local_str_input1 in
            "Y"|"N")
                break
            ;;
            *)
                echo -e "$0: Invalid input."
            ;;
        esac  
        ((local_int_count++))   # counter
    done  
}
#

# parse and execute functions #
local_str_input1=$1
echo -en "$0: PLEASE READ: Automatically answer Yes/No prompts with 'Yes'? [Y/n]: "

if [[ -z $local_str_input1 ]]; then read local_str_input1; fi

local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
local_str_input1=${local_str_input1:0:1}
UserInput $local_str_input1
echo -e "$0: Executing sudo functions."
local_str_dir1="sudo-functions"
declare -a local_arr_dir1=`ls $local_str_dir1`

for local_str_line in $local_arr_dir1; do

    # execute sh/bash scripts in directory
    if [[ $local_str_line == *".sh" ]]; then
        echo -e "\n$0: Executing '$local_str_line'."
        sudo sh $local_str_dir1"/"$local_str_line $local_str_input1
    fi

    if [[ $local_str_line == *".bash" ]]; then
        echo -e "\n$0: Executing '$local_str_line'."
        sudo bash $local_str_dir1"/"$local_str_line $local_str_input1
    fi  
    #
done
#

IFS=$SAVEIFS        # reset IFS
echo "$0: Exiting."
exit 0