#!/bin/bash sh

exit 0

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

### NOTE: clone/update git repos here 

echo "$0: Cloning/Updating Git repos."
cd ~/
str_dir1=$(pwd)'/git/'
if [[ ! -d $str_dir1 ]]; then mkdir -p $str_dir1; fi     # if dir doesn't exist, create it

# here goes useful repos for system deployment
# list of git repos     # NOTE: update here
declare -a arr_repo=(   

#"username/reponame"
"awilliam/rom-parser"
#"pixelplanetdev/4chan-flag-filter"
"pyllyukko/user.js"
"SpaceinvaderOne/Dump_GPU_vBIOS"
"spheenik/vfio-isolate"

)
    
# loop thru list
int_repo=${#arr_repo[@]}
for (( int_index=0; int_index<$int_repo; int_index++ )); do
    
    # reset working dir
    cd ~/
        
    str_repo=${arr_repo[$int_index]}
    str_user=$(echo $str_repo | cut -d "/" -f1)
        
    if [[ ! -d $str_dir1$str_user ]]; then mkdir -p $str_dir1$str_user; fi     # create folder
        
    # update local repo #
    if [[ -e $str_dir1$str_repo ]]; then
        cd $str_dir1$str_repo
        git pull https://github.com/$str_repo
    else
        # validate input variable #
        if [[ $1 != "Y"* ]]; then
            echo -en "$0: Clone repo '$str_repo'? [Y/n]: "
            read str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            UserInput $str_input1

            if [[ $str_input1 != "Y"* ]]; then
                cd $str_dir1$str_user
                git clone https://github.com/$str_repo
            fi

        # automatic input #
        else
            cd $str_dir1$str_user
            git clone https://github.com/$str_repo
        fi
        #
    fi
    #
        
done

### NOTE: execute git scripts here ###

#echo "$0: Executing Git scripts."

# prompt user to execute script or do so automatically #
function ExecuteScript {
    if [[ $1 != "Y" ]]; then
        echo -e "$0: Execute script '$str_repo'?"
        read str_input1
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
    else str_input1="Y"; fi
}
#

### portellam/Auto-Xorg ##
#str_repo="portellam/Auto-Xorg"
#ExecuteScript $str_repo

#if [[ $str_input1 != "Y"* ]]; then
#    cd $str_dir1$str_repo
#    sudo bash ./installer.sh
#fi
##

IFS=$SAVEIFS                # reset IFS
echo -e "$0: Exiting."
exit 0