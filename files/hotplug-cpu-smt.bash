#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Hotplug disable/enable CPU simultaenous multi-threading (SMT),
#               without the use of kernel command line parameter 'nosmt'.
#               Useful if you wish to mitigate exploits that target SMT vulnerabilities.
#

# parameters #
declare -i int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
declare -i int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
# declare -i int_SMT=$((int_totalThreads / int_totalCores))

echo -e "CPU cores:   ${int_totalCores}"
echo -e "CPU threads: ${int_totalThreads}"
# echo -e "SMT multiplier:       ${int_SMT}"
echo

# NOTE: assume that total threads is a multiple of total cores, thus SMT is positive integer.
# bash will round down any decimal to the nearest integer.

# if [[ $int_SMT -le 0 ]]; then
#         echo -e "WARNING: Exception. Invalid SMT value. Exiting."
#         exit 1
# fi

# if [[ $int_SMT -eq 1 ]]; then
#         echo -e "WARNING: SMT is not supported or is disabled in BIOS. Exiting."
#         exit 1
# fi

# if [[ $int_SMT -ge 2 ]]; then
if true; then
        # echo -e "SMT is supported and enabled."

        case $(echo ${1} | tr '[:upper:]' '[:lower:]') in
                "n"*)
                        echo -en "Disabling CPU simultaneous multi-threading (SMT)... "

                        # CREDIT: RedHat Linux distribution knowledgebase
                        # URL:    https://access.redhat.com/solutions/rhel-smt
                        #

                        for str_line1 in $( ls /sys/devices/system/cpu/cpu[0-9]* -d | sort ); do
                                if [[ -e $str_line1/online ]]; then
                                        awk -F '[-,]' '{if(NF > 1) {HOTPLUG="/sys/devices/system/cpu/cpu"$NF"/online"; print "0" > HOTPLUG; close(HOTPLUG)}}' $str_line1/topology/thread_siblings_list 2>/dev/null
                                fi
                        done

                        echo -e "Successful.";;

                "y"*|*)
                        echo -en "Attempting to enable CPU simultaneous multi-threading (SMT)... "

                        for str_line1 in $( ls /sys/devices/system/cpu/cpu[0-9]* -d | sort ); do
                                if [[ -e $str_line1/online ]]; then
                                        echo "1" > ${str_line1}/online
                                fi
                        done

                        echo -e "Successful.";;
        esac
fi

if [[ $int_totalThreads != $( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' ) ]]; then
        declare -i int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
        declare -i int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
        echo -e "\nActive CPU cores:   ${int_totalCores}"
        echo -e "Active CPU threads: ${int_totalThreads}\n"
fi

echo -e "Exiting."
exit 0
