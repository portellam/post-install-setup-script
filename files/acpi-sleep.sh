#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Disable system suspend ACPI wakeup for USB interfaces.
#

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char

declare -a arr_input1=(`cat /proc/acpi/wakeup | grep enabled | grep -Ei '*EHC*|*XHC*'`)
for str_line1 in ${arr_input1[@]}; do
        echo `echo $str_line1 | cut -d ' ' -f1` > /proc/acpi/wakeup
done

IFS=$SAVEIFS   # Restore original IFS
exit 0