#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Hotplug disable/enable CPU simultaenous multi-threading (SMT),
#               without the use of kernel command line parameter 'nosmt'.
#               Useful if you wish to mitigate exploits that target SMT vulnerabilities.
#
# NOTES:
#       make this service into it's own repo?
#       or, split service files in two, one enable, other disable, for convenience
#

# parameters #
declare -i int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
declare -i int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )

echo -e "CPU cores:   ${int_totalCores}"
echo -e "CPU threads: ${int_totalThreads}"
echo

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

if [[ $int_totalThreads != $( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' ) ]]; then
        declare -i int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
        declare -i int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
        echo -e "\nActive CPU cores:   ${int_totalCores}"
        echo -e "Active CPU threads: ${int_totalThreads}\n"
fi

echo -e "Exiting."
exit 0
