#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

### NOTE: clone/update git repos here 

echo "$0: Cloning/Updating Git repos."
local_str_dir1="/root/git/"
if [[ ! -d $local_str_dir1 ]]; then; mkdir -p $local_str_dir1; fi     # if dir doesn't exist, create it

# here goes useful repos for system deployment
# list of git repos     # NOTE: update here
declare -a arr_repo=(   

#"username/reponame"
"foundObjects/zram-swap"
"portellam/Auto-Xorg"
"pyllyukko/user.js"
"StevenBlack/hosts"

)
    
# loop thru list
int_repo=${#arr_repo[@]}
for (( int_index=0; int_index<$int_repo; int_index++ )); do
    
    # reset working dir
    cd ~/
        
    str_repo=${arr_repo[$int_index]}
    str_user=$(echo $str_repo | cut -d "/" -f1)
        
    if [[ ! -d $local_str_dir1$str_user ]]; then; mkdir -p $local_str_dir1$str_user; fi     # create folder
        
    # update local repo #
    if [[ -e $local_str_dir1$str_repo ]]; then
        cd $local_str_dir1$str_repo
        git pull https://github.com/$str_repo
    else
        # validate input variable #
        if [[ $1 != "Y"* ]]; then
            echo -e "$0: Clone repo '$str_repo'?"
            read local_str_input1
            local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')

            if [[ $local_str_input1 != "Y"* ]]; then
                cd $local_str_dir1$str_user
                git clone https://github.com/$str_repo
            fi

        # automatic input #
        else
            cd $local_str_dir1$str_user
            git clone https://github.com/$str_repo
        fi
        #
    fi
    #
        
done

### NOTE: execute git scripts here ###

echo "$0: Executing Git scripts."

# prompt user to execute script or do so automatically #
function ExecuteScript {
    if [[ $1 =! "Y" ]]; then
        echo -e "$0: Execute script '$str_repo'?"
        read local_str_input1
        local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
    else local_str_input1="Y"; fi
}
#

## portellam/Auto-Xorg ##
str_repo="portellam/Auto-Xorg"
ExecuteScript $str_repo

if [[ $local_str_input1 != "Y"* ]]; then
    cd $local_str_dir1$str_repo
    sudo bash ./installer.sh
fi
##

## StevenBlack/hosts ##
str_repo="StevenBlack/hosts"
ExecuteScript $str_repo

if [[ $local_str_input1 != "Y"* ]]; then
    cd $local_str_dir1$str_repo
    local_str_file1="/etc/hosts"

    if [[ -d $local_str_file1'_old' ]]; then; sudo cp $local_str_file1 $local_str_file1'_old'     # backup hosts
    else sudo cp $local_str_file1'_old' $local_str_file1; fi                                    # restore backup

    echo $'\n#' >> $local_str_file1
    cat hosts >> $local_str_file1
fi
##
    
## pyllyukko/user.js ##
str_repo="pyllyukko/user.js"
ExecuteScript $str_repo

if [[ $local_str_input1 != "Y"* ]]; then
    cd $local_str_dir1$str_repo
    make debian_locked.js
    local_str_file1="/etc/firefox-esr/firefox-esr.js"

    if [[ -d $local_str_file1'_old' ]]; then; cp $local_str_file1 $local_str_file1'_old'; fi          # backup system user.js

    cp debian_locked.js $local_str_file1
    #ln -s debian_locked.js /etc/firefox-esr/firefox-esr.js      # NOTE: unused
fi
##
    
## foundObjects/zram-swap ##
str_repo="foundObjects/zram-swap"
ExecuteScript $str_repo

if [[ $local_str_input1 != "Y"* ]]; then
    cd $local_str_dir1$str_repo
    sudo sh ./install.sh
fi
##

IFS=$SAVEIFS                # reset IFS
echo -e "$0: Exiting."
exit 0