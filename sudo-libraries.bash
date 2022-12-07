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

### exit code functions ###
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
        #   131             Neither pass or fail; Skipped execution.
        #
    # </summary>

    # <summary>
        # Output error given exception.
    # </summary>
    function ParseThisExitCode {
        case $int_thisExitCode in
            ### script agnostic ###
            255)
                echo -e "\e[33mError:\e[0m Unspecified error.";;
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

    # <summary>
        # Exit bash session/script with current exit code.
    # </summary>
    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }

    # <summary>
        # Updates main parameter.
    # </summary>
    function SaveThisExitCode {
        int_thisExitCode=$?
    }

    function SetExitCodeOnError {
        (exit 255)
    }

    function SetExitCodeIfVarIsNull {
        (exit 254)
    }

    function SetExitCodeIfFileOrDirIsNull {
        (exit 253)
    }

    function SetExitCodeIfFileIsNotReadable {
        (exit 252)
    }

    function SetExitCodeIfFileIsNotWritable {
        (exit 251)
    }

    function SetExitCodeIfFileIsNotExecutable {
        (exit 250)
    }

    function SetExitCodeIfPassNorFail {
        (exit 131)
    }
# </code>

### exception functions ###
# <code>
    # <summary>
        # Checks if input parameter is null,
        # and returns exit code given result.
    # </summary>
    function CheckIfVarIsNull {
        if [[ -z "$1" ]]; then
            SetExitCodeIfVarIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file exists,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsNull {
        if [[ ! -e $1 ]]; then
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if directory exists,
        # and returns exit code if failed.
    # </summary>
    function CheckIfDirIsNull {
        if [[ ! -d $1 ]]; then
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file is readable,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsReadable {
        if [[ ! -r $1 ]]; then
            SetExitCodeIfFileIsNotReadable; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }

    # <summary>
        # Checks if file is writable,
        # and returns exit code if failed.
    # </summary>
    function CheckIfFileIsWritable {
        if [[ ! -w $1 ]]; then
            SetExitCodeIfFileIsNotWritable; SaveThisExitCode
        else
            true; SaveThisExitCode
        fi
    }
# </code>

### special functions ###
# <code>
    # <summary>
        # Checks if current user is sudo/root.
    # </summary>
    function CheckIfUserIsRoot {
        if [[ $( whoami ) != "root" ]]; then
            local str_thisFile=$( echo ${0##/*} )
            CheckIfFileIsNull $str_thisFile &> /dev/null
            echo -en "\e[33mWARNING:\e[0m"" Script must execute as root. "

            if [[ $int_thisExitCode -eq 0 ]]; then
                readonly str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
                echo -e " In terminal, run:\n\t'sudo bash $str_thisFile'"
            fi

            ExitWithThisExitCode
        fi
    }

    # <summary>
        # Output pass or fail statement given exit code.
    # </summary>
    function EchoPassOrFailThisExitCode {
        CheckIfVarIsNull $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo -en "$1 "
        fi

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mSuccessful. \e[0m";;
            131)
                echo -e "\e[33mSkipped. \e[0m";;
            *)
                echo -e "\e[31mFailed. \e[0m";;
        esac
    }

    # <summary>
        # Output pass or fail test-case given exit code.
    # </summary>
    function EchoPassOrFailThisTestCase {
        str_testCaseName=$1
        CheckIfVarIsNull $str_testCaseName &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            str_testCaseName="TestCase"
        fi

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mPASS:\e[0m""\t$str_testCaseName";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t$str_testCaseName";;
        esac
    }
# </code>

### general functions ###
# <code>
    # <summary>
        # Change ownership of given file to current user.
        # NOTE: $UID is intelligent enough to differentiate between the two
    # </summary>
    function ChangeOwnershipOfFileOrDir {
        CheckIfVarIsNull $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo '$UID =='"'$UID'"
            chown -f $UID $1
        fi
    }

    # <summary>
        # Checks if two given files are the same, in composition.
    # </summary>
    function CheckIfTwoFilesAreSame {
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
                false; SaveThisExitCode
            fi
        fi

        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    # <summary>
        # Checks if two given files are the same, in composition.
    # </summary>
    function CreateBackupFromFile {
        echo -en "Backing up file... "
        declare -lr str_file=$1
        CheckIfVarIsNull $str_file &> /dev/null
        CheckIfFileIsNull $str_file &> /dev/null
        CheckIfFileIsReadable $str_file &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -r str_suffix=".old"
            declare -r str_dir=$( dirname $1 )
            declare -ar arr_dir=( $( ls -1v $str_dir | grep $str_file | grep $str_suffix | uniq ) )

            if [[ "${#arr_dir[@]}" -ge 1 ]]; then           # positive non-zero count
                # <parameters>
                    declare -ir int_maxCount=5
                    str_line=${arr_dir[0]}
                    str_line=${str_line%"${str_suffix}"}    # substitution
                    str_line=${str_line##*.}                # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -ir int_firstIndex="${str_line}"
                else
                    false; SaveThisExitCode                                         # NOTE: redundant?
                fi

                for str_element in ${arr_dir[@]}; do
                    if cmp -s $str_thisFile $str_element; then
                        false; SaveThisExitCode
                        break
                    fi
                done

                # if cmp -s $str_thisFile ${arr_dir[-1]}; then        # if latest backup is same as original file, exit
                #     true; SaveThisExitCode
                # fi

                while [[ ${#arr_dir[@]} -ge $int_maxCount ]]; do    # before backup, delete all but some number of backup files
                    if [[ -e ${arr_dir[0]} ]]; then
                        rm ${arr_dir[0]}
                        break
                    fi
                done

                if cmp -s $str_file ${arr_dir[0]}; then             # if *first* backup is same as original file, exit
                    false; SaveThisExitCode
                fi

                # <parameters>
                    str_line=${arr_dir[-1]%"${str_suffix}"}         # substitution
                    str_line=${str_line##*.}                        # ditto
                # </parameters>

                if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then  # check if string is a valid integer
                    declare -i int_lastIndex="${str_line}"
                else
                    false; SaveThisExitCode
                fi

                (( int_lastIndex++ ))                                               # counter

                if [[ $str_file -nt ${arr_dir[-1]} && ! ( $str_file -ef ${arr_dir[-1]} ) ]]; then       # source file is newer and different than backup, add to backups
                    cp $str_file "${str_file}.${int_lastIndex}${str_suffix}"
                # elif [[ $str_file -ot ${arr_dir[-1]} && ! ( $str_file -ef ${arr_dir[-1]} ) ]]; then
                #     false; SaveThisExitCode
                else
                    false; SaveThisExitCode
                fi
            else
                cp $str_file "${str_file}.0${str_suffix}"           # no backups, create backup
                SaveThisExitCode                                    # NOTE: redundant?
            fi
        fi

        EchoPassOrFailThisExitCode
        ParseThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "No changes from most recent backup."
        fi
    }

    # <summary>
        # Creates a file.
    # </summary>
    function CreateFile {
        echo -en "Creating file... "
        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/Null

        if [[ $int_thisExitCode -eq 0 ]]; then
            touch $1 &> /dev/null
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Deletes a file.
    # </summary>
    function DeleteFile {
        echo -en "Deleting file... "
        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            rm $1 &> /dev/null
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Reads a file.
    # </summary>
    function ReadFile {
        echo -en "Reading file... "
        CheckIfVarIsNull $1 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null
        CheckIfFileIsReadable $1 &> /dev/null
        declare -la arr_file=()

        while read str_line; do
            arr_file+=("$str_line") || ( (exit 249); SaveThisExitCode; arr_file=(); break )
        done < $1

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Ask for Yes/No answer, return boolean,
        # Default selection is N/false.
        # Aways returns bool.
    # </summary>
    function ReadInput {
        # <parameters> #
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )
        # </parameters> #

        for int_element in ${arr_count[@]}; do
            echo -en "$1 \e[30;43m[Y/n]:\e[0m "
            read str_input
            str_input=$( echo $str_input | tr '[:lower:]' '[:upper:]' )

            case $str_input in
                "Y"|"N")
                    break;;
                *)
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input="N"
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m ";;
            esac
        done

        case $str_input in
            "Y")
                true;;
            "N")
                false;;
        esac

        SaveThisExitCode; echo
    }

    # <summary>
        # Ask for multiple choice, up to eight choices.
        # Default selection is first choice.
        # Proper use always returns valid answer.
    # </summary>
    function ReadInputFromMultipleChoiceIgnoreCase {
        CheckIfVarIsNull $2 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            # <parameters> #
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )
            # </parameters> #

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input
                # str_input=$( echo $str_input | tr '[:lower:]' '[:upper:]' )

                if [[ -z $2 && $str_input == $2 ]]; then
                    break
                elif [[ -z $3 && $str_input == $3 ]]; then
                    break
                elif [[ -z $4 && $str_input == $4 ]]; then
                    break
                elif [[ -z $5 && $str_input == $5 ]]; then
                    break
                elif [[ -z $6 && $str_input == $6 ]]; then
                    break
                elif [[ -z $7 && $str_input == $7 ]]; then
                    break
                elif [[ -z $8 && $str_input == $8 ]]; then
                    break
                elif [[ -z $9 && $str_input == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    SetExitCodeIfFileOrDirIsNull
                fi
            done
        fi

        SaveThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Ask for multiple choice, up to eight choices.
        # Default selection is first choice.
        # Proper use always returns valid answer.
    # </summary>
    function ReadInputFromMultipleChoiceUpperCase {
        CheckIfVarIsNull $2 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            # <parameters> #
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )
            # </parameters> #

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input
                str_input=$( echo $str_input | tr '[:lower:]' '[:upper:]' )

                if [[ ! -z $2 && $str_input == $2 ]]; then
                    break
                elif [[ ! -z $3 && $str_input == $3 ]]; then
                    break
                elif [[ ! -z $4 && $str_input == $4 ]]; then
                    break
                elif [[ ! -z $5 && $str_input == $5 ]]; then
                    break
                elif [[ ! -z $6 && $str_input == $6 ]]; then
                    break
                elif [[ ! -z $7 && $str_input == $7 ]]; then
                    break
                elif [[ ! -z $8 && $str_input == $8 ]]; then
                    break
                elif [[ ! -z $9 && $str_input == $9 ]]; then
                    break
                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    SetExitCodeIfFileOrDirIsNull
                fi
            done
        fi

        SaveThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Ask for multiple choice, up to eight choices.
        # Default selection is first choice.
        # Proper use always returns valid answer.
    # </summary>
    function ReadInputFromRangeOfNums {
        # <parameters> #
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )
        # </parameters> #

        for int_element in ${arr_count[@]}; do
            echo -en "$1 "
            read str_input

            if [[ $str_input -ge $2 && $str_input -le $3 ]]; then     # valid input
                break
            else
                if [[ $int_element -eq $int_maxCount ]]; then           # default input
                    str_input=$2                                        # default selection: first choice
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input\e[0m"
                    break
                fi

                # if [[ ! ( "${str_input}" -ge "$(( ${str_input} ))" ) ]] 2> /dev/null; then  # check if string is a valid integer
                #     echo -en "\e[33mInvalid input.\e[0m "
                # fi

                echo -en "\e[33mInvalid input.\e[0m "
            fi
        done
    }

    # <summary>
        # Test network connection to Internet.
        # Ping DNS servers by address and name.
    # </summary>
    function TestNetwork {
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || false

        SaveThisExitCode; EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || false

        SaveThisExitCode; EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    # <summary>
        # NOTE: not working!
        # Input variable #2 ( $2 ) is the name of the variable we wish to point to.
        # This may help with calling/parsing arrays.
        # When passing the var, write the name without " $ ".
    # </summary>
    function WriteArrayToFile {
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char
        var_input=$2

        echo -en "Writing to file... "
        CheckIfVarIsNull $1 &> /dev/null
        CheckIfVarIsNull $var_input &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null
        CheckIfFileIsReadable $1 &> /dev/null
        CheckIfFileIsWritable $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            case ${!var_input[@]} in                                                    # check number of key-value pairs
                0)                                                                      # check if var is not an array
                    echo -e $var_input >> $1 || ( SetExitCodeOnError; SaveThisExitCode );;
                *)                                                                      # check if var is an array
                    for str_element in ${var_input[@]}; do
                        echo -e $str_element >> $1 || ( SetExitCodeOnError; SaveThisExitCode; break )
                    done;;
            esac
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
        # Input variable #2 ( $2 ) is the name of the variable we wish to point to.
        # This may help with calling/parsing arrays.
        # When passing the var, write the name without " $ ".
    # </summary>
    function WriteVarToFile {
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)    # NOTE: necessary for newline preservation in arrays and files
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "
        CheckIfVarIsNull $1 &> /dev/null
        CheckIfVarIsNull $2 &> /dev/null
        CheckIfFileIsNull $1 &> /dev/null
        CheckIfFileIsReadable $1 &> /dev/null
        CheckIfFileIsWritable $1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo -e $2 >> $1 || false; SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }
# </code>

### executive functions ###
# <code>
    # <summary>
        # Check linux distro
    # </summary>
    function CheckCurrentDistro {
        if [[ $(command -v apt) == "/usr/bin/apt" ]]; then
            true; SaveThisExitCode
        else
            echo -e "\e[33mWARNING:\e[0m"" Unrecognized Linux distribution. Continuing with minimal setup."
            false; SaveThisExitCode
        fi
    }

    # <summary>
        # Clone remote or update local Git repositories.
    # </summary>
    function CloneOrUpdateGitRepositories {
        echo -en "Cloning Git repositories... "
        CheckIfVarIsNull $1; CheckIfVarIsNull $2
        CheckIfDirIsNull $1; CheckIfDirIsNull $2
        CheckIfFileIsWritable $1; CheckIfFileIsWritable $2

        if [[ $int_thisExitCode -eq 0 ]]; then
            cd $1

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
                        git pull $str_element &> /dev/null || ( ((int_count++)) && SetExitCodeIfPassNorFail )
                        cd ..

                    else                                    # clone new repo
                        git clone $str_element &> /dev/null || ( ((int_count++)) && SetExitCodeIfPassNorFail )
                    fi

                done

                if [[ ${#2[@]} -eq $int_count ]]; then      # if all repos failed to clone, change exit code
                    SetExitCodeOnError
                fi

            else                                            # git clone a repo
                echo $2 >> $1 || SetExitCodeOnError
            fi
        fi

        SaveThisExitCode; EchoPassOrFailThisExitCode; ParseThisExitCode

        case $int_thisExitCode in
            131)
                echo -e "One or more Git repositories could not be cloned.";;
        esac

        echo
    }
# </code>

### main functions ###
# <code>
    # <summary>
        # Display Help to console.
    # </summary>
    function Help {
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

    # <summary>
        # Parse input parameters for given options.
    # </summary>
    function ParseInputParamForOptions {
        if [[ "$1" =~ ^- || "$1" == "--" ]]; then           # parse input parameters
            while [[ "$1" =~ ^-  ]]; do
                case $1 in
                    "")                                     # no option
                        SetExitCodeOnError
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
            SetExitCodeOnError
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

    # <summary>
        # Set software repositories for Debian Linux.
    # </summary>
    function ModifyDebianRepos {
        echo -e "Modifying $(lsb_release -is) $(uname -o) repositories..."

        # <parameters>
        str_file1="/etc/apt/sources.list"
        str_oldFile1="${str_file1}_old"
        str_newFile1="${str_file1}_new"
        str_releaseName=$(lsb_release -sc)
        str_releaseVer=$(lsb_release -sr)
        str_sources=""
        # </parameters>

        # create backup or restore from backup
        if [ -z $str_file1 ]; then
            cp $str_file1 $str_oldFile1
        fi

        # prompt user to change apt dependencies
        while true; do

            # prompt for alt sources
            str_input1=""
            ReadInput "Include 'contrib' sources?"

            case $str_input1 in
                "Y")
                    str_sources="contrib";;

                *)
                    ;;
            esac

            str_input1=""
            ReadInput "Include 'non-free' sources?"

            case $str_input1 in
                "Y")
                    str_sources+=" non-free";;

                *)
                    ;;
            esac

            # manual prompt
            if [[ $int_count -ge 3 ]]; then
                echo -e "Exceeded max attempts!"
                str_input2=stable     # default input     # NOTE: change here

            else
                echo -e "Repositories: Enter one valid option or none for default (Current branch: $str_releaseName)."
                echo -e "\tWARNING: It is NOT possible to revert from a Non-stable branch back to a Stable or $str_releaseName branch."
                echo -e "\tRelease branches:"
                echo -e "\t\t'stable'\t== '$str_releaseName'"
                echo -e "\t\t'testing'\t*more recent updates, slightly less stability"
                echo -e "\t\t'unstable'\t*most recent updates, least stability. NOT recommended."
                echo -e "\t\t'backports'\t== '$str_releaseName-backports'\t*optionally receive more recent updates."
                echo -en "\tEnter option: "

                read str_input2
                str_input2=$(echo $str_input2 | tr '[:upper:]' '[:lower:]')   # string to lowercase
            fi

            # exit with no changes
            if [[ $str_input2 == "stable" ]]; then
                echo -e "No changes. Skipping."
                break
            fi

            # apt sources
            declare -a arr_sources=(
                "# debian $str_input2"
                "# See https://wiki.debian.org/SourcesList for more information."
                "deb http://deb.debian.org/debian/ $str_input2 main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_input2 main $str_sources"
                $'\n'
                "deb http://deb.debian.org/debian/ $str_input2-updates main $str_sources"
                "deb-src http://deb.debian.org/debian/ $str_input2-updates main $str_sources"
                $'\n'
                "deb http://security.debian.org/debian-security/ $str_input2-security main $str_sources"
                "deb-src http://security.debian.org/debian-security/ $str_input2-security main $str_sources"
                "#"
            )

            # copy lines from original to temp file as comments
            if [[ -e $str_newFile1 ]]; then
                rm $str_newFile1
            fi

            touch $str_newFile1

            while read str_line1; do
                if [[ $str_line1 != "#"* ]]; then
                    str_line1="#$str_line1"
                fi

                echo $str_line1 >> $str_newFile1
            done < $str_file1

            if [[ -e $str_file1 ]]; then
                rm $str_file1
            fi

            mv $str_newFile1 $str_file1

            # delete optional sources file, if it exists
            if [ -e '/etc/apt/sources.list.d/'$str_input2'.list' ]; then
                rm '/etc/apt/sources.list.d/'$str_input2'.list'
            fi

            # input prompt
            case $str_input2 in

                # valid choices
                "testing"|"unstable")

                    echo -e "\tSelected \"$str_input2\"."

                    # write to file #
                    int_line1=${#arr_sources[@]}

                    for (( int_i=0; int_i<$int_line1; int_i++ )); do
                        str_line1=${arr_sources[$int_i]}
                        echo $str_line1 >> '/etc/apt/sources.list.d/'$str_input2'.list'
                    done

                    break;;

                # current branch with backports
                "backports")

                    echo -e "\tSelected \"$str_input2\"."

                    # apt sources
                    declare -a arr_sources=(
        $'\n'
        "# debian $str_releaseVer/$str_releaseName"
        "# See https://wiki.debian.org/SourcesList for more information."
        "deb http://deb.debian.org/debian/ $str_releaseName main $str_sources"
        "deb-src http://deb.debian.org/debian/ $str_releaseName main $str_sources"
        $'\n'
        "deb http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
        "deb-src http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
        $'\n'
        "deb http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
        "deb-src http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
        "#"
        "# debian $str_releaseVer/$str_releaseName $str_input2"
        "deb http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
        "deb-src http://deb.debian.org/debian $str_releaseName-$str_input2 main contrib non-free"
        "#"
        )
                    # write to file
                    int_line1=${#arr_sources[@]}

                    for (( int_i=0; int_i<$int_line1; int_i++ )); do
                        str_line1=${arr_sources[$int_i]}
                        echo $str_line1 >> '/etc/apt/sources.list.d/'$str_input2'.list'
                    done

                    break;;

                # invalid selection
                *)
                    echo -e "Invalid input."

            esac
            ((int_count++))     # counter
        done

        if [[ -e $str_newFile1 ]]; then
                rm $str_newFile1
        fi

        sudo apt clean
        sudo apt update
        sudo apt full-upgrade

        # clean up
        # sudo apt autoremove -y
    }

    # <summary>
        # Install system service from repository.
        # Finds first available non-VFIO VGA/GPU and binds to Xorg.
    # </summary>
    function SetupAutoXorg {
        echo -e "Installing Auto-Xorg... "
        ( cd $( find -wholename Auto-Xorg | uniq | head -n1 ) && bash ./installer.bash ) || ( false && SaveThisExitCode)
        cd $str_pwd
        EchoPassOrFailThisExitCode; ParseThisExitCode; echo
    }

    # <summary>
        # Executes deployment of a Debian Linux system.
    # </summary>
    function ExecuteSetupOfSoftwareSources {
        CheckCurrentDistro

        if [[ $int_thisExitCode -eq 0 ]]; then
            ModifyDebianRepos
        fi

        echo -e "\nWARNING: If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
    }
# </code>

### main ###
# <code>
    # NOTE: necessary for newline preservation in arrays and files
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    CheckIfUserIsRoot
    ExecuteSetupOfSoftwareSources
    ExitWithThisExitCode
# </code>