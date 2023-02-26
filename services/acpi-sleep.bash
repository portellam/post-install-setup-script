#!/bin/bash

#
# Author:       Alex Portell <https://github.com/portellam>
# Description:  Disable system suspend ACPI wakeup for USB interfaces.
#

# <code>
SAVEIFS=$IFS
IFS=$'\n'

for var_line in $( cat /proc/acpi/wakeup | grep enabled | grep -Ei '*EHC*|*XHC*' | cut -d ' ' -f1 ); do
	echo $var_line > /proc/acpi/wakeup || exit 1
done

IFS=$SAVEIFS
exit 0
# </code>