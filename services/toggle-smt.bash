#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Hotplug disable/enable CPU simultaenous multi-threading (SMT),
#               without the use of kernel command line parameter 'nosmt'.
#               Useful if you wish to mitigate exploits that target SMT vulnerabilities.
#

# parameters #
declare -i int_initialTotalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
declare -i int_initialTotalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
declare -r str_input1=$( echo ${1} | tr '[:upper:]' '[:lower:]' )

echo -e "CPU cores:   ${int_initialTotalCores}"
echo -e "CPU threads: ${int_initialTotalThreads}"
echo

case ${str_input1} in
        "n"*)
                echo -en "Attemping to disable CPU simultaneous multi-threading (SMT)... "

                # CREDIT: RedHat Linux distribution knowledgebase
                # URL:    https://access.redhat.com/solutions/rhel-smt
                #

                for str_line1 in $( ls /sys/devices/system/cpu/cpu[0-9]* -d | sort ); do
                        if [[ -e ${str_line1}/online ]]; then
                                awk -F '[-,]' '{if(NF > 1) {HOTPLUG="/sys/devices/system/cpu/cpu"$NF"/online"; print "0" > HOTPLUG; close(HOTPLUG)}}' ${str_line1}/topology/thread_siblings_list 2>/dev/null
                        fi
                done;;

        "y"*|*)
                echo -en "Attempting to enable CPU simultaneous multi-threading (SMT)... "

                for str_line1 in $( ls /sys/devices/system/cpu/cpu[0-9]* -d | sort ); do
                        if [[ -e ${str_line1}/online ]]; then
                                echo "1" > ${str_line1}/online
                        fi
                done;;
esac


if [[ ${int_initialTotalThreads} != $( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' ) ]]; then
        echo -e "Successful."
        declare -i int_initialTotalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
        echo -e "Active CPU threads: ${int_initialTotalThreads}\n"

else
        echo -en "Failed.\nWARNING: No changes made. "

        case ${str_input1} in
                "n"*)
                        echo -e "SMT already disabled.";;

                "y"*|*)
                        echo -e "SMT already enabled.";;
        esac
fi

echo -e "Exiting."
exit 0
