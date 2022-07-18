#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# skip or stop at every user-input #
function UserInput {
    
    # PARAMETERS #
    declare -i local_int_count=0            # reset counter
    if [[ -e $1 ]]; then local_str_input1=$1; fi   # $1 input variable
    #

    while true; do

        # manual prompt #
        if [[ $local_int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts!"
            local_str_input1="N"                     # default input     # NOTE: change here

        else                                        # manual prompt
            echo -en "$0: Skip or stop at each user-input prompt (automically answer yes/no prompts with yes)?\n$0: [Y/n]: "
            read local_str_input1

            # string to upper
            local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
            local_str_input1=${local_str_input1:0:1}
            #
        fi
        #
        
        case $local_str_input1 in
            "Y")
                echo -e "$0: Skipping at each user-input prompt."
                break
            ;;
            "N")
                echo -e "$0: Stopping at each user input prompt."
                break
            ;;
            *)  echo -e "$0: Invalid input!";;
        esac
        
        ((local_int_count++))   # counter
    done
    
}
#

UserInput $1

# parse and execute functions #
echo -e "$0: Executing functions."

local_str_dir="functions"
declare -a local_arr_dir=`ls $local_str_dir`

for local_str_line in $local_arr_dir; do

    # execute sh/bash scripts in directory
    if [[ $local_str_line == *".sh" ]]; then
        echo -e "$0: Executing '$local_str_line'."
        #sudo sh $local_str_dir"/"$local_str_line $local_str_input1
    fi

    if [[ $local_str_line == *".bash" ]]; then
        echo -e "$0: Executing '$local_str_line'."
        #sudo bash $local_str_dir"/"$local_str_line $local_str_input1
        sudo bash $local_str_dir"/"$local_str_line
    fi  
    #

done
#

IFS=$SAVEIFS        # reset IFS
echo "$0: Exiting."
exit 0
