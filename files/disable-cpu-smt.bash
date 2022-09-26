#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Disable/enable CPU simultaenous multi-threading (SMT),
#               without the use of kernel command line parameter 'nosmt'.
#

# parameters #
declare -ir int_totalCores=$(cat /proc/cpuinfo | grep 'cpu cores' | uniq | cut -d ':' -f2 | cut -d ' ' -f2)
declare -ir int_totalThreads=$(cat /proc/cpuinfo | grep 'siblings' | uniq | cut -d ':' -f2 | cut -d ' ' -f2)
declare -ir int_SMT=$((int_totalThreads / int_totalCores))

echo -e "Total CPU cores:     ${int_totalCores}"
echo -e "Total CPU threads:   ${int_totalThreads}"
echo -e "SMT multiplier:      ${int_SMT}"
echo

# NOTE: assume that total threads is a multiple of total cores, thus SMT is positive integer.
# bash will round down any decimal to the nearest integer.

if [[ $int_SMT -le 0 ]]; then
        echo -e "WARNING: Exception. Invalid SMT value. Exiting."
        exit 1
fi

if [[ $int_SMT -eq 1 ]]; then
        echo -e "WARNING: SMT is not supported or is disabled in BIOS. Exiting."
        exit 1
fi

if [[ $int_SMT -ge 2 ]]; then
        echo -e "SMT is supported and enabled."

        case ${1} in
                "Y"*|*)
                        readonly bool=true
                        echo -e "Disabling CPU simultaneous multi-threading (SMT).";;
                "N"*)
                        readonly bool=false
                        echo -e "Enabling CPU simultaneous multi-threading (SMT).";;
        esac

        echo

        # parse all CPU threads #
        for (( int_cpuID=0 ; int_cpuID < ${int_totalThreads} ; int_cpuID++ )); do
                str_line1="/sys/devices/system/cpu/cpu${int_cpuID}"

                # re-enable all CPUs (redundant)
                if test -e ${str_line1}/online; then
                        echo -e "Enabled core thread: ${int_cpuID}"
                        echo "1" > ${str_line1}/online
                fi

                eval "COREENABLE=\"\${core${int_cpuID}enable}\""

                # change function given input variable #
                if [[ $bool == true ]]; then

                        # disable SMT; disable CPU thread (id non-zero)
                        if [[ ! ${COREENABLE:-true} ]]; then
                                echo -e "Disabled SMT thread: ${int_cpuID}"
                                echo "0" > "$str_line1/online"

                        # re-enable CPU thread (id zero) (redundant)
                        else
                                echo -e "Enabled core thread: ${int_cpuID}"
                                eval "core${int_cpuID}enable='false'"
                        fi

                # enable SMT; enable all CPUs
                else
                        echo -e "Enabled core thread: ${int_cpuID}"
                        # echo "1" > $str_line1/online
                fi
        done
fi

exit 0