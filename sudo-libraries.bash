#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

### main parameters ###
# <code>
    declare -r str_pwd=$( pwd )

    # <summary>
        # Necessary for exit code preservation, for conditional statements.
    # </summary>
    declare -i int_thisExitCode=$?
# </code>

### exception functions ###
# <code>
    # <summary>
        # This statement (function) must follow an exit code statement.
        #   Exit Code   |   Description
        #
        #   0               True
        #   1               False; Catch-all for general errors.
        #   2               Misuse of shell built-ins.
        #
        #   126             Command invoked cannot execute.
        #   127             Command not found.
        #   128             Invalid argument to exit.
        #   128 +n          Where 'n' is a number, '$?' returns '128 + n'.
        #   130             Script terminated by 'CTRL+C'.
        #
        #   131-255         Unreserved
        #
        #   255             Unspecified error.
        #   254             Input is null.
        #   253             File/Dir is null.
        #   252             File/Dir is not readable.
        #   251             File/Dir is not writable.
        #   250             File/Dir is not executable.
        #
    # </summary>

    # <summary>
        # Updates main parameter.
    # </summary>
    function SaveThisExitCode {
        int_thisExitCode=$?
    }

    # <summary>
        # Checks if input parameter is null,
        # and returns exit code given result.
    # </summary>
    function CheckIfVarIsNull {
        if [[ -z $1 ]]; then
            (exit 254) && SaveThisExitCode
        else
            true && SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file or directory exists,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsNull {
        if [[ ! -e $1 ]]; then
            (exit 253) && SaveThisExitCode
        else
            true && SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file is readable,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsReadable {
        if [[ ! -r $1 ]]; then
            (exit 252) && SaveThisExitCode
        else
            true && SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file is writable,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsWritable {
        if [[ ! -w $1 ]]; then
            (exit 251) && SaveThisExitCode
        else
            true && SaveThisExitCode
        fi
    }

    # <summary>
        # Output error given exception.
    # </summary>
    function ParseThisExitCode {
        case $int_thisExitCode in
            ### script agnostic ###
            254)
                echo -e "\e[33mException:\e[0m Null input.";;

            ### file operands ###
            253)
                echo -e "\e[33mException:\e[0m File/Dir does not exist.";;
            252)
                echo -e "\e[33mException:\e[0m File/Dir is not readable.";;
            251)
                echo -e "\e[33mException:\e[0m File/Dir is not writable.";;
            249)
                echo -e "\e[33mException:\e[0m Invalid input.";;

            ### script specific ###
            248)
                echo -e "\e[33mError:\e[0m Missed steps; missed execution of key subfunctions.";;
            251)
                echo -e "\e[33mError:\e[0m Missing components/variables.";;
        esac
    }
# </code>

### special functions ###
# <code>
    # <summary>
        # Checks if current user is sudo/root.
    # </summary>
    function CheckIfUserIsRoot
    {
        if [[ $( whoami ) != "root" ]]; then
            SaveThisExitCode
            local str_thisFile=$( echo ${0##/*} )
            readonly str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
            echo -en "\e[33mWARNING:\e[0m"" Script must execute as root."
            CheckIfFileIsNull $str_thisFile &> /dev/null || echo -e " In terminal, run:\n\t'sudo bash $str_thisFile'"
            ExitWithThisExitCode
        fi
    }

    # <summary>
        # Output pass or fail statement given exit code.
    # </summary>
    function EchoPassOrFailThisExitCode
    {
        CheckIfVarIsNull $1 &> /dev/null || echo -en "$1"

        case "$int_thisExitCode" in
            0)
                echo -e " \e[32mSuccessful. \e[0m";;
            131)
                echo -e " \e[33mSkipped. \e[0m";;
            *)
                echo -e " \e[31mFailed. \e[0m";;
        esac
    }

    # <summary>
        # Output pass or fail test-case given exit code.
    # </summary>
    function EchoPassOrFailThisTestCase
    {
        str_testCaseName=$1
        CheckIfVarIsNull $str_testCaseName &> /dev/null || str_testCaseName="TestCase"

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mPASS:\e[0m""\t$str_testCaseName";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t$str_testCaseName";;
        esac
    }

    # <summary>
        # Exit bash session/script with current exit code.
    # </summary>
    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }
# </code>

### general functions ###
# <code>
    # function ChangeOwnershipOfFileOrDir
        # {
        #     # behavior:
        #     # change ownership of existing file to current user
        #     # current user may be the sudoer or root (either is not necessarily the same)
        #     # note: $UID is intelligent enough to differentiate between the two
        #     #

        #     if [[ -z $1 ]]; then        # null exception
        #         (exit 254)
        #         SaveThisExitCode
        #     else
        #         echo '$UID =='"'$UID'"
        #         chown -f $UID $1
        #         (exit 0)
        #         SaveThisExitCode
        #     fi
        # }

    # <summary>
        # Checks if two given files are the same, in composition.
    # </summary>
    function CheckIfTwoFilesAreSame
    {
        echo -e "Verifying two files... "

        CheckIfVarIsNull $1 &> /dev/null
        CheckIfVarIsNull $2 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null
        CheckIfFileIsNull $2 &> /dev/null
        CheckIfFileIsReadable $1 &> /dev/null
        CheckIfFileIsReadable $2 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            if cmp -s "$1" "$2"; then
                echo -e 'Positive Match.\n\t"%s"\n\t"%s"' "$1" "$2"
            else
                echo -e 'False Match.\n\t"%s"\n\t"%s"' "$1" "$2"
                false && SaveThisExitCode
            fi
        fi

        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    # <summary>
        # Checks if two given files are the same, in composition.
    # </summary>
    function CreateBackupFromFile
    {
        echo -en "Backing up file... "
        declare -lr str_thisFile=$1

        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null
        CheckIfFileIsReadable $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -r str_suffix=".old"
            declare -r str_thisDir=$( dirname $1 )
            declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

            if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then       # positive non-zero count
                # <parameters>
                    declare -ir int_maxCount=5
                    str_line=${arr_thisDir[0]}
                    str_line=${str_line%"${str_suffix}"}    # substitution
                    str_line=${str_line##*.}                # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -ir int_firstIndex="${str_line}"
                else
                    false && SaveThisExitCode                                       # NOTE: redundant?
                fi

                for str_element in ${arr_thisDir[@]}; do
                    if cmp -s $str_thisFile $str_element; then
                        false && SaveThisExitCode
                        break
                    fi
                done

                if cmp -s $str_thisFile ${arr_thisDir[-1]}; then        # if latest backup is same as original file, exit
                    true && SaveThisExitCode
                fi

                while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do    # before backup, delete all but some number of backup files
                    if [[ -e ${arr_thisDir[0]} ]]; then
                        rm ${arr_thisDir[0]}
                        break
                    fi
                done

                if cmp -s $str_thisFile ${arr_thisDir[0]}; then         # if *first* backup is same as original file, exit
                    false && SaveThisExitCode
                fi

                # <parameters>
                    str_line=${arr_thisDir[-1]%"${str_suffix}"}         # substitution
                    str_line=${str_line##*.}                            # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -i int_lastIndex="${str_line}"
                else
                    false && SaveThisExitCode
                fi

                (( int_lastIndex++ ))                                               # counter

                if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then       # source file is newer and different than backup, add to backups
                    cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"
                elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                    false && SaveThisExitCode
                else
                    false && SaveThisExitCode
                fi
            else
                cp $str_thisFile "${str_thisFile}.0${str_suffix}"   # no backups, create backup
                SaveThisExitCode                                    # NOTE: redundant?
            fi
        fi

        EchoPassOrFailThisExitCode                                  # call functions
        ParseThisExitCode

        case $int_thisExitCode in                                   # append output and return code
            255)
                echo -e "No changes from most recent backup.";;
        esac
    }

    # <summary>
        # Creates a file.
    # </summary>
    function CreateFile
    {
        echo -en "Creating file... "

        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null && (
            touch $1 &> /dev/null || ( false && SaveThisExitCode )
        )

        EchoPassOrFailThisExitCode      # call functions
        ParseThisExitCode
    }

    # <summary>
        # Deletes a file.
    # </summary>
    function DeleteFile
    {
        echo -en "Deleting file... "

        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null || (
            rm $1 &> /dev/null || ( false && SaveThisExitCode )
        )

        EchoPassOrFailThisExitCode          # call functions
        ParseThisExitCode
    }


    function ReadFile
    {
        echo -en "Reading file... "

        if [[ -z $1 ]]; then        # null exception
            (exit 254)
            SaveThisExitCode
        fi

        if [[ ! -e $1 ]]; then      # file not found exception
            (exit 250)
            SaveThisExitCode
        fi

        if [[ ! -r $1 ]]; then      # file is not readable exception
            (exit 249)
            SaveThisExitCode
        fi

        declare -la arr_output_thisFile=()

        while read str_line; do
            arr_output_thisFile+=("$str_line") || ( (exit 249) && SaveThisExitCode && arr_output_thisFile=() && break )
        done < $1

        EchoPassOrFailThisExitCode  # call functions
        ParseThisExitCode
    }

    function ReadInput
    {
        # behavior:
        # ask for Yes/No answer, return boolean,
        # default selection is N/false
        # always returns bool
        #

        # parameters #
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 \e[30;43m[Y/n]:\e[0m "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            case $str_input1 in
                "Y"|"N")
                    break;;
                *)
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1="N"
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m ";;
            esac
        done

        case $str_input1 in
            "Y")
                true;;
            "N")
                (exit 131);;
        esac

        SaveThisExitCode        # call functions
        echo
    }

    function ReadInputFromMultipleChoiceIgnoreCase
    {
        # behavior:
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)
        else

            # parameters
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                # str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ -z $2 && $str_input1 == $2 ]]; then
                    break
                elif [[ -z $3 && $str_input1 == $3 ]]; then
                    break
                elif [[ -z $4 && $str_input1 == $4 ]]; then
                    break
                elif [[ -z $5 && $str_input1 == $5 ]]; then
                    break
                elif [[ -z $6 && $str_input1 == $6 ]]; then
                    break
                elif [[ -z $7 && $str_input1 == $7 ]]; then
                    break
                elif [[ -z $8 && $str_input1 == $8 ]]; then
                    break
                elif [[ -z $9 && $str_input1 == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        SaveThisExitCode    # call functions
        ParseThisExitCode
    }

    function ReadInputFromMultipleChoiceUpperCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)
        else

            # parameters #
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ ! -z $2 && $str_input1 == $2 ]]; then
                    break
                elif [[ ! -z $3 && $str_input1 == $3 ]]; then
                    break
                elif [[ ! -z $4 && $str_input1 == $4 ]]; then
                    break
                elif [[ ! -z $5 && $str_input1 == $5 ]]; then
                    break
                elif [[ ! -z $6 && $str_input1 == $6 ]]; then
                    break
                elif [[ ! -z $7 && $str_input1 == $7 ]]; then
                    break
                elif [[ ! -z $8 && $str_input1 == $8 ]]; then
                    break
                elif [[ ! -z $9 && $str_input1 == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        SaveThisExitCode    # call functions
        ParseThisExitCode
    }

    function ReadInputFromRangeOfNums
    {
        # behavior:
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        # parameters #
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 "
            read str_input1

            if [[ $str_input1 -ge $2 && $str_input1 -le $3 ]]; then     # valid input
                break
            else
                if [[ $int_element -eq $int_maxCount ]]; then           # default input
                    str_input1=$2                                       # default selection: first choice
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                    break
                fi

                # if [[ ! ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null; then  # check if string is a valid integer
                #     echo -en "\e[33mInvalid input.\e[0m "
                # fi

                echo -en "\e[33mInvalid input.\e[0m "
            fi
        done
    }



    function TestNetwork
    {
        # behavior:
        #   test internet connection and DNS servers
        #   return boolean, to be used by main
        #

        # test IP resolution #
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || false

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || false

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    function WriteArrayToFile
    {
        # TODO: not working!

        # behavior:
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char
        var_input=$2

        echo -en "Writing to file... "

        if [[ -z $1 || -z $var_input ]]; then   # null exception
            (exit 254)
        fi

        if [[ ! -e $1 ]]; then          # file not found exception
            (exit 253)
        fi

        if [[ ! -r $1 ]]; then          # file not readable exception
            (exit 252)
        fi

        if [[ ! -w $1 ]]; then          # file not readable exception
            (exit 251)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            case ${!var_input[@]} in                                                    # check number of key-value pairs
                0)                                                                      # check if var is not an array
                    echo -e $var_input >> $1 || ( (exit 255) && SaveThisExitCode );;
                *)                                                                      # check if var is an array
                    for str_element in ${var_input[@]}; do
                        echo -e $str_element >> $1 || ( (exit 255) && SaveThisExitCode && break )
                    done;;
            esac
        fi

        SaveThisExitCode                # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function WriteVarToFile
    {
        # behavior:
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "

        if [[ -z $1 || -z $2 ]]; then   # null exception
            (exit 254)
        fi

        if [[ ! -e $1 ]]; then          # file not found exception
            (exit 253)
        fi

        if [[ ! -r $1 ]]; then          # file not readable exception
            (exit 252)
        fi

        if [[ ! -w $1 ]]; then          # file not readable exception
            (exit 251)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo -e $2 >> $1 || (exit 255)
        fi

        SaveThisExitCode                # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }
# </code>

# executive functions #
    function CheckIfIOMMU_IsEnabled
    {
        echo -en "Checking if Virtualization is enabled/supported... "

        # call functions #
        if [[ ! -z $( compgen -G "/sys/kernel/iommu_groups/*/devices/*" ) ]]; then
            SaveThisExitCode
            EchoPassOrFailThisExitCode
        else
            SaveThisExitCode
            EchoPassOrFailThisExitCode
            ParseThisExitCode
            ExitWithThisExitCode
        fi
    }

    function CloneOrUpdateGitRepositories
    {
        echo -en "Cloning Git repositories... "

        # dir #
        if [[ -z $1 || -z $2 ]]; then       # null exception
            (exit 254)
        fi

        if [[ ! -d $1 ]]; then              # dir not found exception
            (exit 250)
        fi

        if [[ ! -w $1 ]]; then              # dir not writeable exception
            (exit 248)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            cd $1

            # git repos #
            if [[ -z $1 || -z $2 ]]; then   # null exception
                (exit 254)
            fi

            if [[ ! -d $1 ]]; then          # dir not found exception
                (exit 250)
            fi

            if [[ ! -w $1 ]]; then          # dir not writeable exception
                (exit 248)
            fi
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then

            # if a given element is a string longer than one char, the var is an array #
            for str_element in ${2}; do
                if [[ ${#str_element} -gt 1 ]]; then
                    bool_varIsAnArray=true
                    break
                fi
            done

            declare -i int_count=1

            if [[ $bool_varIsAnArray == true ]]; then       # git clone from array
                for str_element in ${2}; do
                    if [[ -e $( basename $1 ) ]]; then      # cd into repo, update, and back out
                        cd $( basename $1 )
                        git pull $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                        cd ..

                    else                                    # clone new repo
                        git clone $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                    fi

                done

                if [[ ${#2[@]} -eq $int_count ]]; then      # if all repos failed to clone, change exit code
                    (exit 255)
                fi

            else                                            # git clone a repo
                echo $2 >> $1 || (exit 255)
            fi
        fi

        SaveThisExitCode                                    # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        case $int_thisExitCode in
            131)
                echo -e "One or more Git repositories could not be cloned.";;
        esac

        echo
    }

    function SetupAutoXorg
    {
        declare -r str_pwd=$( pwd )
        echo -e "Installing Auto-Xorg... "
        cd $( find -wholename Auto-Xorg | uniq | head -n1 ) && bash ./installer.bash && cd $str_pwd
        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode
        ParseThisExitCode
        echo
    }

    function SetupEvdev
    {
        # behavior:
        # ask user to prep setup of Evdev
        # add active desktop users to groups for Libvirt, QEMU, Input devices, etc.
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="/logs/qemu-evdev.log"
        declare -r str_thisFile2="/etc/apparmor.d/abstractions/libvirt-qemu"

        echo -e "Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
        ReadInput "Setup Evdev?"

        if [[ $int_thisExitCode -eq 0 ]]; then
            # declare -r str_firstUser=$( id -u 1000 -n ) && echo -e "Found the first desktop user of the system: $str_firstUser"

            # add users to groups #
            declare -a arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # output to file #
            CheckIfFileIsNull $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            ( CreateFile $str_thisFile1 ) || false

            if [[ $int_thisExitCode -eq 0 ]]; then

                # list of input devices #
                declare -ar arr_InputDeviceID=($( ls /dev/input/by-id ))
                declare -ar arr_InputEventDeviceID=($( ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0' ))
                declare -a arr_output_evdevQEMU=()

                for str_element in ${arr_InputDeviceID[@]}; do                          # append output
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                for str_element in ${arr_InputEventDeviceID[@]}; do                     # append output
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                declare -r arr_output_evdevQEMU

                # append output #
                declare -ar arr_output_evdevApparmor=(
                    "  "
                    "  # Generated by 'portellam/deploy-VFIO-setup'"
                    "  #"
                    "  # WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
                    "  #"
                    "  # Run 'systemctl restart apparmor.service' to update."
                    "  "
                    "  # Evdev #"
                    "  /dev/input/* rw,"
                    "  /dev/input/by-id/* rw,"
                )

                # debug #
                # echo -e '${#arr_InputDeviceID[@]}='"'${#arr_InputDeviceID[@]}'"
                # echo -e '${#arr_InputEventDeviceID[@]}='"'${#arr_InputEventDeviceID[@]}'"
                # echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

                CheckIfFileIsNull $str_thisFile1

                if [[ $int_thisExitCode -eq 0 ]]; then                                                      # append file
                    for str_element in ${arr_output_evdevQEMU[@]}; do
                        WriteVarToFile $str_thisFile1 $str_element &> /dev/null || ( false && break )       # should this loop fail at any given time, exit
                    done
                fi

                # NOTE: will require restart of apparmor service or system
                if [[ $int_thisExitCode -eq 0 ]]; then
                    CheckIfFileIsNull $str_thisFile2 &> /dev/null

                    if [[ $int_thisExitCode -eq 0 ]]; then                                                  # append file
                        for str_element in ${arr_output_evdevApparmor[@]}; do
                            WriteVarToFile $str_thisFile2 $str_element &> /dev/null || ( false && break )   # should this loop fail at any given time, exit
                        done

                        echo $arr_output_evdevQEMU &> /dev/null || false
                    fi
                fi
            fi
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode "Setup Evdev..."
        ParseThisExitCode
    }

    function SetupHugepages
    {
        # behavior:
        # find vars necessary for Hugepages setup
        # function can never *fail*, just execute or exit
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="/logs/qemu-hugepages.log"
        declare -ir int_HostMemMaxK=$( cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 )      # sum of system RAM in KiB
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                                # default output

        echo -e "Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n"
        ReadInput "Setup Hugepages?"

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -ar arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))   # add users to groups

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # prompt #
            ReadInputFromMultipleChoiceUpperCase "Enter Hugepage size and byte-size \e[30;43m[1G/2M]:\e[0m" "1G" "2M"
            str_HugePageSize=$str_input1

            declare -ir int_HostMemMinK=4194304         # min host RAM in KiB

            case $str_HugePageSize in                   # Hugepage Size
                "2M")
                    declare -ir int_HugePageK=2048      # Hugepage size
                    declare -ir int_HugePageMin=2;;     # min HugePages
                "1G")
                    declare -ir int_HugePageK=1048576   # Hugepage size
                    declare -ir int_HugePageMin=1;;     # min HugePages
            esac

            declare -ir int_HugePageMemMax=$(( $int_HostMemMaxK - $int_HostMemMinK ))
            declare -ir int_HugePageMax=$(( $int_HugePageMemMax / $int_HugePageK ))       # max HugePages

            # prompt #
            ReadInputFromRangeOfNums "Enter number of HugePages (n * $str_HugePageSize) \e[30;43m[$int_HugePageMin <= n <= $int_HugePageMax pages]:\e[0m" $int_HugePageMin $int_HugePageMax
            declare -ir int_HugePageNum=$str_input1

            # output #
            declare -r str_output_hugepagesGRUB="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
            declare -r str_output_hugepagesQEMU="hugetlbfs_mount = \"/dev/hugepages\""

            # write to file #
            CheckIfFileIsNull $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            CreateFile $str_thisFile1 &> /dev/null

            if [[ $int_thisExitCode -eq 0 ]]; then
                WriteVarToFile $str_thisFile1 $str_output_hugepagesQEMU &> /dev/null && echo
            fi
        fi

        # SaveThisExitCode                                  # call functions
        EchoPassOrFailThisExitCode "Setup Hugepages..."
        ParseThisExitCode
    }

    function SetupStaticCPU_isolation
    {
        echo -e "CPU isolation (Static or Dynamic) is a feature which allocates system CPU threads to the host and Virtual machines (VMs), separately.\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit\n\t'Static' is more 'permanent' CPU isolation: installation will append to GRUB after VFIO setup.\n\tAlternatively, 'Dynamic' CPU isolation is flexible and on-demand: post-installation will execute as a libvirt hook script (per VM)."
        ReadInput "Setup 'Static' CPU isolation?" && echo -en "Executing CPU isolation setup... " && ParseCPU
        EchoPassOrFailThisExitCode              # call functions
        echo
    }

    function SetupZRAM_Swap
    {
        # parameters #
        declare -lr str_pwd=$( pwd )

        # prompt #
        echo -e "Installing zram-swap... "

        # TODO: change this!
        if [[ $( systemctl status asshole &> /dev/null ) != *"could not be found"* ]]; then
            systemctl stop zramswap &> /dev/null
            systemctl disable zramswap &> /dev/null
        fi

        ( cd $( find -wholename zram-swap | uniq | head -n1 ) && sh ./install.sh && cd $str_pwd ) || (exit 255)

        # setup ZRAM #
        if [[ $int_thisExitCode -eq 0 ]]; then

            # disable all existing zram swap devices
            if [[ $( swapon -v | grep /dev/zram* ) == "/dev/zram"* ]]; then
                swapoff /dev/zram* &> /dev/null
            fi

            declare -lir int_hostMemMaxG=$(( int_HostMemMaxK / 1048576 ))
            declare -lir int_sysMemMaxG=$(( int_hostMemMaxG + 1 ))

            echo -e "Total system memory: <= ${int_sysMemMaxG}G.\nIf 'Z == ${int_sysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."

            # free memory #
            if [[ ! -z $str_HugePageSize && ! -z $int_HugePageNum ]]; then
                case $str_HugePageSize in
                    "1G")
                        declare -lir int_hugePageSizeK=1048576;;

                    "2M")
                        declare -lir int_hugePageSizeK=2048;;
                esac

                declare -lir int_hugepagesMemG=$int_HugePageNum*$int_hugePageSizeK/1048576
                declare -lir int_hostMemFreeG=$int_sysMemMaxG-$int_hugepagesMemG
                echo -e "Free system memory after hugepages (${int_hugepagesMemG}G): <= ${int_hostMemFreeG}G."
            else
                declare -lir int_hostMemFreeG=$int_sysMemMaxG
                echo -e "Free system memory: <= ${int_hostMemFreeG}G."
            fi

            str_output1="Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): "

            ReadInputFromRangeOfNums "Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): " 0 $int_hostMemFreeG
            declare -lir int_ZRAM_sizeG=$str_input1

            # while true; do

            #     # attempt #
            #     if [[ $int_count -ge 2 ]]; then
            #         ((int_ZRAM_sizeG=int_hostMemFreeG/2))      # default selection
            #         echo -e "Exceeded max attempts. Default selection: ${int_ZRAM_sizeG}G"
            #         break

            #     else
            #         if [[ -z $int_ZRAM_sizeG || $int_ZRAM_sizeG -lt 0 || $int_ZRAM_sizeG -ge $int_hostMemFreeG ]]; then
            #             echo -en "\e[33mInvalid input.\e[0m\n$str_output1"
            #             read -r int_ZRAM_sizeG

            #         else
            #             break
            #         fi
            #     fi

            #     ((int_count++))
            # done

            declare -lir int_denominator=$(( $int_sysMemMaxG / $int_ZRAM_sizeG ))
            str_output1="\n_zram_fraction=\"1/$int_denominator\""
            # str_outFile1="/etc/default/zramswap"
            str_outFile1="/etc/default/zram-swap"

            CreateBackupFromFile $str_outFile1
            WriteVarToFile $str_outFile1 $str_output1 || (exit 255)
        fi

        SaveThisExitCode            # call functions
        EchoPassOrFailThisExitCode "Zram-swap setup "
        ParseThisExitCode
        echo
    }

# main functions #
    function Help
    {
        declare -r str_helpPrompt="Usage: $0 [ OPTIONS | ARGUMENTS ]
            \nwhere OPTIONS
            \n\t-h  --help\t\t\tPrint this prompt.
            \n\t-d  --delete\t\t\tDelete existing VFIO setup.
            \n\t-w  --write <logfile>\t\tWrite output (IOMMU groups) to <logfile>
            \n\t-m  --multiboot <ARGUMENT>\tExecute Multiboot VFIO setup.
            \n\t-s  --static <ARGUMENT>\t\tExecute Static VFIO setup.
            \n\nwhere ARGUMENTS
            \n\t-f  --full\t\t\tExecute pre-setup and post-setup.
            \n\t-r  --read <logfile>\t\tRead previous output (IOMMU groups) from <logfile>, and update VFIO setup.
            \n"

        echo -e $str_helpPrompt

        ExitWithThisExitCode
    }


    function ParseInputParamForOptions
    {
        if [[ "$1" =~ ^- || "$1" == "--" ]]; then           # parse input parameters
            while [[ "$1" =~ ^-  ]]; do
                case $1 in
                    "")                                     # no option
                        (exit 255)
                        SaveThisExitCode
                        break;;

                    -h | --help )                           # options
                        declare -lir int_aFlag=1
                        break;;
                    -d | --delete )
                        declare -lir int_aFlag=2
                        break;;
                    -m | --multiboot )
                        declare -lir int_aFlag=3;;
                    -s | --static )
                        declare -lir int_aFlag=4;;
                    -w | --write )
                        declare -lir int_aFlag=5;;

                    -f | --full )                           # arguments
                        declare -lir int_bFlag=1;;
                    -r | --read )
                        declare -lir int_bFlag=2;;
                esac

                shift
            done
        else                                                # invalid option
            (exit 255)
            SaveThisExitCode
            ParseThisExitCode
            Help
            ExitWithThisExitCode
        fi

        # if [[ "$1" == '--' ]]; then
        #     shift
        # fi

        case $int_aFlag in                                  # execute second options before first options
            3|4)
                case $int_bFlag in
                    1)
                        PreInstallSetup;;
                    # 2)
                    #     ReadIOMMU_FromFile;;
                esac;;
        esac

        case $int_aFlag in                                  # execute first options
            1)
                Help;;
            2)
                DeleteSetup;;
            3)
                MultiBootSetup;;
            4)
                StaticSetup;;
            # 5)
            #     WriteIOMMU_ToFile;;
        esac

        case $int_aFlag in                                  # execute second options after first options
            3|4)
                case $int_bFlag in
                    1)
                        PostInstallSetup;;
                esac;;
        esac
    }

# main #
    # NOTE: necessary for newline preservation in arrays and files
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    bool_executeDeleteSetup=false
    bool_executeFullSetup=false
    bool_executeMultiBootSetup=false
    bool_executeStaticSetup=false
    bool_executeDeleteSetup=false

    if [[ -z $2 ]]; then
        # ParseInputParamForOptions $1            # TODO: need to fix params function
        CheckIfUserIsRoot
        CheckIfIOMMU_IsEnabled

        case true in
            $bool_executeDeleteSetup)
                DeleteSetup;;
            $bool_executeFullSetup)
                PreInstallSetup
                SelectVFIOSetup
                PostInstallSetup;;
            $bool_executeMultiBootSetup)
                MultiBootSetup;;
            $bool_executeStaticSetup)
                StaticSetup;;
            *)
                SelectVFIOSetup;;
        esac
    else
        (exit 254)
        SaveThisExitCode
        ParseThisExitCode "Cannot parse multiple options."
    fi

    # if [[ -z $2 ]]; then
    #     CheckIfUserIsRoot
    #     CheckIfIOMMU_IsEnabled
    #     ParseInputParamForOptions_2 $1 || SelectVFIOSetup
    # else
    #     (exit 254)
    #     SaveThisExitCode
    #     ParseThisExitCode "Cannot parse multiple options."
    # fi

    ExitWithThisExitCode