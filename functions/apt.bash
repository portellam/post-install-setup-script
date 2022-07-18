#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

# exit if distro is NOT Debian
str_distroName=$(lsb_release -i | grep 'Distributor ID')
str_distroName=$(echo $str_distroName | tr '[:lower:]' '[:upper:]')

if [[ $str_distroName != *"DEBIAN"* ]]; then
    echo -e "$0: Script cannot continue. System distribution is NOT Debian Linux. Exiting."
    exit 0
fi
#

# find release codename #
str_releaseName=$(lsb_release -c | grep Codename)
((int_releaseName=${#str_releaseName}-10))
str_releaseName=(${str_releaseName:10:$int_releaseName})
#
    
# find current release name #
str_releaseVer=$(lsb_release -r | grep Release)
((int_releaseVer=${#str_releaseVer}-9))
str_releaseVer=(${str_releaseVer:9:$int_releaseVer})
#

local_str_file="/etc/apt/sources.list"      # set working file
    
# create backup or restore from backup #
if [ ! -d $local_str_file ]; then
    cp $local_str_file $local_str_file'_old'
else
    cp $local_str_file'_old' $local_str_file
fi
#

# prompt user to change apt dependencies #
while true; do

    # prompt for non-free sources #
    if [[ -z $local_str_input1 ]]; then
        echo -en "$0: Include non-free sources? [Y/n]: "
        read local_str_input1
        local_str_input1=$(echo $local_str_input1 | tr '[:lower:]' '[:upper:]')
        local_str_input1=${local_str_input1:0:1}

        case $local_str_input1 in
            "Y")
                str_sources=" non-free contrib";;

            *)
                str_sources=" contrib";;
        esac

    fi
    #
        
    # manual prompt #
    if [[ $int_count -ge 3 ]]; then
        echo -e "$0: Exceeded max attempts!"
        local_str_input2=stable     # default input     # NOTE: change here
    
    else
        echo -e "$0: Dependencies: Enter one valid option or none for default (Current branch: $str_releaseName)."
        echo -e "WARNING: It is NOT possible to revert from a Non-stable branch back to a Stable or $str_releaseName branch."
        echo -e "\nRelease branches:"
        echo -e "\t'stable'\t== '$str_releaseName'"
        echo -e "\t'testing'\t*more recent updates, slightly less stability"
        echo -e "\t'unstable'\t*most recent updates, least stability. NOT recommended for new and/or average users."
        echo -e "Others:"
        echo -e "\t'backports'\t== '$str_releaseName-backports'\t*optionally receive most recent updates, at user descretion. Recommended."
        echo -en "\n$0: Enter option: "

        read local_str_input2
        local_str_input2=$(echo $local_str_input2 | tr '[:upper:]' '[:lower:]')   # string to lowercase
    fi

    # exit with no changes #
    if [[ $local_str_input2 == "stable" ]]; then
        echo -e "$0: No changes. Skipping."
        break
    fi;
    #

    # apt sources
    declare -a arr_sources=(
"# debian $local_str_input2"
"# See https://wiki.debian.org/SourcesList for more information."
"deb http://deb.debian.org/debian/ $local_str_input2 main$str_sources"
"deb-src http://deb.debian.org/debian/ $local_str_input2 main$str_sources"
$'\n'
"deb http://deb.debian.org/debian/ $local_str_input2-updates main$str_sources"
"deb-src http://deb.debian.org/debian/ $local_str_input2-updates main$str_sources"
$'\n'
"deb http://security.debian.org/debian-security/ $local_str_input2-security main$str_sources"
"deb-src http://security.debian.org/debian-security/ $local_str_input2-security main$str_sources"
"#"
)

    # copy lines from original to temp file as comments #
    touch $local_str_file'_temp'

    while read str_line; do
        echo '#'$str_line >> $local_str_file'_temp'
    done < $local_str_file

    cat $local_str_file'_temp' > $local_str_file
    #

    # delete optional sources file, if it exists #
    if [ -e '/etc/apt/sources.list.d/'$local_str_input2'.list' ]; then
        rm '/etc/apt/sources.list.d/'$local_str_input2'.list'
    fi
    #

    # input prompt #
    case $local_str_input2 in
            
        # testing #
        "testing")
                
            echo -e "$0: Selected \"$local_str_input2\"."

            # loop thru array #
            local_int_line=${#arr_sources[@]}
            for (( int_index=0; int_index<$local_int_line; int_index++ )); do
                str_line=${arr_sources[$int_index]}
                echo $str_line >> '/etc/apt/sources.list.d/'$local_str_input2'.list'
            done
            #
                
            break;;
        #

        # unstable #
        "unstable")
                
            echo -e "$0: Selected \"$local_str_input2\"."

            # loop thru array #
            local_int_line=${#arr_sources[@]}
            for (( int_index=0; int_index<$local_int_line; int_index++ )); do
                str_line=${arr_sources[$int_index]}
                echo $str_line >> '/etc/apt/sources.list.d/'$local_str_input2'.list'
            done
            #
                
            break;;
        #

        # current branch with backports
        "backports")
            
            echo -e "$0: Selected \"$local_str_input2\"."
                
            # apt sources 
            declare -a arr_sources=(
$'\n'
"# debian $str_releaseVer/$str_releaseName"
"# See https://wiki.debian.org/SourcesList for more information."
"deb http://deb.debian.org/debian/ $str_releaseName main$str_sources"
"deb-src http://deb.debian.org/debian/ $str_releaseName main$str_sources"
$'\n'
"deb http://deb.debian.org/debian/ $str_releaseName-updates main$str_sources"
"deb-src http://deb.debian.org/debian/ $str_releaseName-updates main$str_sources"
$'\n'
"deb http://security.debian.org/debian-security/ $str_releaseName-security main$str_sources"
"deb-src http://security.debian.org/debian-security/ $str_releaseName-security main$str_sources"
"#"
"# debian $str_releaseVer/$str_releaseName $local_str_input2"
"deb http://deb.debian.org/debian $str_releaseName-$local_str_input2 main contrib non-free"
"deb-src http://deb.debian.org/debian $str_releaseName-$local_str_input2 main contrib non-free"
"#"
)

            # loop thru array #
            local_int_line=${#arr_sources[@]}
            for (( int_index=0; int_index<$local_int_line; int_index++ )); do
                str_line=${arr_sources[$int_index]}
                echo $str_line >> '/etc/apt/sources.list.d/'$local_str_input2'.list'
            done
            #

            break;;
        #
            
        # invalid selection #
        *)
            echo -e "$0: Invalid input!"
        #
                
    esac
        
    ((int_count++))     # counter  
done
#

rm $local_str_file'_temp'   # remove temp file
echo -en "$0: Updating system.\nWARNING: If System Update is prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a'"
sudo apt clean
sudo apt update

# input variable
if [[ $1 == "Y"* ]]; then
    sudo apt full-upgrade -y
    sudo apt autoremove -y
else
    sudo apt full-upgrade
    sudo apt autoremove
fi
#

IFS=$SAVEIFS        # reset IFS
echo "$0: Exiting."
exit 0