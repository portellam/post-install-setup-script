#!/bin/bash sh

## METHODS start ##

function 01_SSH {
    echo "SSH: Start."
    cd ~/
    
    # WORKING DIRECTORY
    str_dir=".ssh/"
    
    # CHECK IF FILES EXIST
    if [[ -d $str_dir'id_rsa' || -d $str_dir'id_rsa.pub' ]]; then
        ssh-keygen -t rsa
    fi
    
    echo "SSH: End."
}

function 02_Git {
    echo "Git: Start."
    cd ~/
    
    # NOTE: update here!
    declare -a arr_repo=(
    #"username/reponame"
    "awilliam/rom-parser"
    "corna/me_cleaner"
    "dt-zero/me_cleaner"
    "foundObjects/zram-swap"
    "pixelplanetdev/4chan-flag-filter"
    "pyllyukko/user.js"
    "SpaceinvaderOne/Dump_GPU_vBIOS"
    "spheenik/vfio-isolate"
    "StevenBlack/hosts"
    )
    
    # LENGTH OF ARRAY
    int_repo=${#arr_repo[@]}    
    
    # WORKING DIRECTORY
    str_dir="git/"
    
    # CHECK IF DIRECTORY EXISTS
    if [ -d $str_dir ]; then
        mkdir -p $str_dir
    fi
    
    # LOOP THRU ARRAY
    for (( int_index=0; int_index<$int_repo; int_index++ )); do
        # RESET WORKING DIRECTORY
        cd ~/
        
        # FIND STRING AT INDEX
        str_repo=${arr_repo[$int_index]}
        
        # SPLIT STRING, FIND USERNAME
        str_user=$(echo $str_repo | cut -d "/" -f1)
        
        # CHECK IF DIRECTORY EXISTS
        if [ ! -d $str_dir$str_user ]; then
            mkdir -p $str_dir$str_user
        fi
        
        # UPDATE LOCAL REPO IF DIRECTORY EXISTS
        if [ -e $str_dir$str_repo ]; then
            cd $str_dir$str_repo
            git pull https://github.com/$str_repo
        # ELSE, CLONE REPO
        else
            cd $str_dir$str_user
            git clone https://github.com/$str_repo
        fi
    done
    
    echo "Git: End."
}

## METHODS end ##

## MAIN start ##

echo "Script: Start."

01_SSH
02_Git

echo "Script: End."
exit 0

## MAIN end ##
