#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Disable system suspend ACPI wakeup for USB interfaces.
#

declare -a arr_input1=`cat /proc/acpi/wakeup | grep enabled | grep -E 'EHC|XHC'`
for str_line1 in $arr_input1; do
    sudo `echo $str_line1 | cut -d ' ' -f 1` > /proc/acpi/wakeup
done
exit 0