#!/bin/bash sh

### disclaimer ###
#
# Author(s):    Alex Portell <github.com/portellam>
#
###

### notes ###
# <summary>
#
# declare -l is NOT declare a local parameter
# it is lowercase
# likewise, declare -u is uppercase
#
# set proper declare options for all vars
#   review PDF
#
# -use alias commands?
#
# -do not over-rely on existing functions for file manipulation, better to use commands than hope logic works as intended.
#
# -refactor *return statements* of functions with first input variable
#   -set $1 as return string/var, and push back other input vars ($1 will be $2, and so on...)
#
# -de-nest code:
#   -place nested conditionals in functions
#   -use while loops, watch for changes in exit code
# -use consistent vocabulary in names, comments, etc
# -refactor code
#
# -cat EOF
#
# use awk, grep, cut, paste
#
# </summary>
###

### exit code functions ###
# <summary> Return statement logic. </summary>
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
    #   128 + n         Where 'n' is a number, '$?' returns '128 + n'.
    #   130             Script terminated by 'CTRL+C'.
    #
    #   131-255         Unreserved
    #
    #   255             Unspecified error.
    #   254             Var is null.
    #   253             File/Dir is null.
    #   252             File/Dir is not readable.
    #   251             File/Dir is not writable.
    #   250             File/Dir is not executable.
    #   249             "Input" is invalid.
    #   131             Neither pass or fail; Skipped execution.
    #
    # </summary>

    # <summary> Append output with string, and output pass or fail statement given boolean. </summary>
    # <parameter name="$1"> bool </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> void </returns>
    function EchoPassOrFailThisBool
    {
        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            echo -en "$2 "
        fi

        if [[ $1 == true ]]; then
            echo -e "\e[32mSuccessful. \e[0m"
        else
            echo -e "\e[31mFailed. \e[0m"
        fi
    }

    # <summary> Append output with string, and output pass or fail statement given exit code. </summary>
    # <parameter name="$1"> exit code </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> void </returns>
    function EchoPassOrFailThisExitCode
    {
        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            echo -en "$2 "
        fi

        case "$1" in
            0)
                echo -e "\e[32mSuccessful.\e[0m";;
            131)
                echo -e "\e[33mSkipped.\e[0m";;
            *)
                echo -e "\e[31mFailed.\e[0m";;
        esac
    }

    # <summary> Append output with string, and output pass or fail statement given exit code. </summary>
    # <parameter name="$1"> exit code </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> void </returns>
    function EchoPassOrFailThisTestCase
    {
        case "$1" in
            0)
                echo -en "\e[32mPASS:\e[0m""\t";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t";;
        esac

        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            echo -e "$2"
        else
            echo -e "unknown test case"
        fi
    }

    # <summary> Exit bash session/script with current exit code. </summary>
    # <parameter name="$1"> exit code </parameter>
    # <returns> void </returns>
    function ExitWithThisExitCode
    {
        echo -e "Exiting."

        if [[ $( CheckIfVarIsValidNumReturnBool $1 ) == true ]]; then
            exit $1
        else
            SetExitCodeOnError; exit
        fi
    }

    # <summary> Output error given exception. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> void </returns>
    function ParseThisExitCode
    {
        # <parameters>
        declare -lr int_exitCode=$?     # This local variable shall not be placed after any line, otherwise unintended behavior will occur.
        # </parameters>

        if [[ $( CheckIfVarIsValidNumReturnBool $int_exitCode ) == false ]]; then
            echo -e "\e[33mException:\e[0m Exit code is not valid."
        else
            case $int_exitCode in
                # <summary> general errors </summary>
                255)
                    echo -e "\e[33mError:\e[0m Unspecified error.";;
                254)
                    echo -e "\e[33mException:\e[0m Null input.";;

                # <summary> file validation </summary>
                253)
                    echo -e "\e[33mException:\e[0m File/Dir does not exist.";;
                252)
                    echo -e "\e[33mException:\e[0m File/Dir is not readable.";;
                251)
                    echo -e "\e[33mException:\e[0m File/Dir is not writable.";;
                250)
                    echo -e "\e[33mException:\e[0m File/Dir is not executable.";;

                # <summary> script specific </summary>
                249)
                    echo -e "\e[33mException:\e[0m Invalid input.";;
                248)
                    echo -e "\e[33mError:\e[0m Missed steps; missed execution of key subfunctions.";;
                247)
                    echo -e "\e[33mError:\e[0m Missing components/variables.";;
            esac
        fi
    }

    # <summary> Updates global parameter. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> void </returns>
    function SaveThisExitCode
    {
        int_exitCode=$?
    }

    # <summary> Given last exit code, return a boolean. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> boolean </returns>
    function ParseThisExitCodeAsBool
    {
        # <parameters>
        declare -r int_exitCode=$?     # This local variable shall not be placed after any line, otherwise unintended behavior will occur.
        local bool=false
        # </parameters>

        if [[ $( CheckIfVarIsValidNumReturnBool $int_exitCode ) == true && "$int_exitCode" -eq 0 ]]; then
            bool=true
        fi

        echo $bool
    }

    # <summary> Set exit codes based on reserved/custom conditions. </summary>
    # <code>
        function SetExitCodeOnError
        {
            (exit 255)
        }

        function SetExitCodeIfVarIsNull
        {
            (exit 254)
        }

        function SetExitCodeIfFileOrDirIsNull
        {
            (exit 253)
        }

        function SetExitCodeIfFileIsNotReadable
        {
            (exit 252)
        }

        function SetExitCodeIfFileIsNotWritable
        {
            (exit 251)
        }

        function SetExitCodeIfFileIsNotExecutable
        {
            (exit 250)
        }

        function SetExitCodeIfInputIsInvalid
        {
            (exit 249)
        }

        function SetExitCodeIfPassNorFail
        {
            (exit 131)
        }
    # </code>
# </code>
###

### validation functions ###
# <summary> Validation logic </summary>
# <code>
    # <summary> Check if command exists, and return boolean. </summary>
    # <parameter name="$1"> command name </parameter>
    # <returns> boolean </returns>
    function CheckIfCommandExistsReturnBool
    {
        local bool=false

        if [[
            $( CheckIfVarIsNotNullReturnBool $1 ) == true
            && (
                $( command -v $1 ) != ""
                || $( command -v $1 ) == "/usr/bin/$1"
            ) ]]; then
            bool=true
        fi

        echo $bool
    }

    # <summary> Check if directory exists, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> directory </parameter>
    # <returns> boolean </returns>
    function CheckIfDirIsNotNullReturnBool
    {
        local bool=false

        if [[ -d $1 && $( CheckIfVarIsNotNullReturnBool $1 ) == true ]]; then
            bool=true
        else
            SetExitCodeIfVarIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if file is executable, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsExecutableReturnBool
    {
        local bool=false

        if [[ -x $1 && $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
        else
            SetExitCodeIfFileIsNotExecutable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if file exists, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileExistsReturnBool
    {
        local bool=false

        if [[ -e $1 ]]; then
            bool=true
        else
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if file is readable, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsReadableReturnBool
    {
        local bool=false

        if [[ -r $1 && $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
        else
            SetExitCodeIfFileIsNotReadable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if file is writable, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsWritableReturnBool
    {
        local bool=false

        if [[ -w $1 && $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
        else
            SetExitCodeIfFileIsNotWritable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if current user is sudo/root, and return boolean. </summary>
    # <parameter name="$0"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfUserIsRootReturnBool
    {
        local bool=false

        if [[ $( whoami ) == "root" ]]; then
            bool=true
        else
            echo -en "${str_warning}Script must execute as root."

            if [[ $( CheckIfFileExistsReturnBool $0 ) == false ]]; then
                declare -lr str_file1=$( basename $0 )
                echo -e " In terminal, run:\n\t'sudo bash ${str_file1}'"
            fi
        fi

        echo $bool
    }

    # <summary> Check if input parameter is null, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> a variable </parameter>
    # <returns> boolean </returns>
    function CheckIfVarIsNotNullReturnBool
    {
        local bool=false

        if [[ ! -z "$1" ]]; then
            bool=true
        else
            SetExitCodeIfVarIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Check if input parameter is a valid number, and return boolean. If false, set exit code. </summary>
    # <parameter name="$1"> a number </parameter>
    # <returns> boolean </returns>
    function CheckIfVarIsValidNumReturnBool
    {
        local bool=false

        if [[ "$1" -eq "$(( $1 ))" ]] 2> /dev/null; then
            bool=true
        else
            SetExitCodeIfInputIsInvalid; SaveThisExitCode
        fi

        echo $bool
    }
# </code>
##

### general functions ###
# <summary> File operation logic </summary>
# <code>
    # <summary> Append file with array, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array </parameter>
    # <returns> boolean </returns>
    function AppendArrayToFileReturnBool
    {
        declare -lr IFS=$'\n'
        local bool=false

        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            bool=true
            local -n arr_file1="$2"
            ( printf "%s\n" "${arr_file1[@]}" >> $1 || bool=false ) &> /dev/null
        fi

        echo $bool
    }

    # <summary> Append file with string, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> boolean </returns>
    function AppendVarToFileReturnBool
    {
        local bool=false

        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            bool=true
            ( echo -e $2 >> $1 || bool=false ) &> /dev/null
        fi

        echo $bool
    }

    # <summary> Change ownership of given file to current user, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function ChangeOwnershipOfFileOrDirToCurrentUserReturnBool
    {
        local bool=false

        if [[ $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
            ( chown -f $UID $1 || bool=false ) &> /dev/null
        fi

        echo $bool
    }

    # <summary> Check if two given files are the same, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfTwoFilesAreSameReturnBool
    {
        local bool=false

        if [[
            $( cmp -s "$1" "$2" )
            && $( CheckIfFileIsReadableReturnBool $1 ) == true
            && $( CheckIfFileIsReadableReturnBool $2 ) == true
            ]]; then
            bool=true
        fi

        echo $bool
    }

    # <summary> Check if given file exists in given directory, and return boolean. </summary>
    # <parameter name="$1"> directory </parameter>
    # <parameter name="$2"> file </parameter>
    function CheckIfFileExistsInDirReturnBool
    {
        # <parameters>
        local bool=false
        declare -lr str_dir1=$( dirname $1 )
        declare -alr arr_dir1=( $( ls -1v $str_dir | grep $2 | grep $str_suffix | uniq ) )
        # </parameters>

        for var_element1 in ${arr_dir1[@]}; do
            if [[ $( CheckIfTwoFilesAreSameReturnBool $2 $var_element1 ) == true ]]; then
                bool=true
                break
            fi
        done

        echo $bool
    }

    # <summary> Create latest backup of given file (do not exceed given maximum count), and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> bool </returns>
    function CreateBackupFromFileReturnBool
    {
        # <parameters>
        local bool=false
        declare -lr str_file1=$1
        # </parameters>

        # <summary> First code block. </summary>
        while [[ ${int_exitCode} -eq 0 ]]; do
            if [[ $( CheckIfFileIsReadableReturnBool $1 ) == false ]]; then
                false; SaveThisExitCode
            fi

            # <parameters>
            declare -lr str_suffix=".old"
            declare -lr str_dir1=$( dirname $1 )
            declare -alr arr_dir1=( $( ls -1v $str_dir | grep $str_file1 | grep $str_suffix | uniq ) )
            # </parameters>

            if [[ "${#arr_dir1[@]}" -eq 0 ]]; then
                ( cp $str_file1 "${str_file1}.0${str_suffix}" || ( false; SaveThisExitCode ) ) &> /dev/null
            fi

            # <parameters>
                declare -ir int_maxCount=5
                local var_element1=${arr_dir1[0]}
                var_element1=${var_element1%"${str_suffix}"}             # substitution
                var_element1=${var_element1##*.}                         # ditto
            # </parameters>

            # <summary> Validate counter. Parse all files, check for match. </summary>
            if [[ $( CheckIfVarIsValidNumReturnBool $var_element1 ) == false || $( CheckIfFileExistsInDirReturnBool $str_dir1 $ ) == false ]]; then
                false; SaveThisExitCode
            fi

            break
        done

        # <summary> Second code block. </summary>
        if [[ ${int_exitCode} -eq 0 ]]; then
            # <summary> Before backup, delete all but some number of backup files; Delete first file until file count equals maxmimum. </summary>
            while [[ ${#arr_dir1[@]} -ge $int_maxCount ]]; do
                bool=$( DeleteFileReturnBool ${arr_dir1[0]} )

                # <summary> Break outside this one while loop, not any above. </summary>
                if [[ $bool == true ]]; then
                    break
                fi
            done
        fi

        # <summary> Last code block; execute if prior validation passes. </summary>
        while [[ $bool == false ]]; do
            # <summary> If *first* backup is same as original file, exit. </summary>
            bool=$( CheckIfTwoFilesAreSameReturnBool $1 ${arr_dir[0]} )

            # <parameters>
            var_element1=${arr_dir1[-1]%"${str_suffix}"}            # substitution
            var_element1=${var_element1##*.}                        # ditto
            declare -il int_lastIndex=0
            # </parameters>

            if [[ $( CheckIfVarIsValidNumReturnBool $var_element1 ) == true ]]; then
                declare -i int_lastIndex="${var_element1}"
                (( int_lastIndex++ ))                               # counter
            fi

            # <summary> Source file is newer and different than backup, add to backups. </summary>
            if [[ $str_file1 -nt ${arr_dir1[-1]} && ! ( $str_file1 -ef ${arr_dir1[-1]} ) ]]; then
                ( cp $str_file1 "${str_file1}.${int_lastIndex}${str_suffix}" || bool=true ) &> /dev/null
            fi

            break
        done

        echo $bool
    }

    # <summary> Create directory, and return boolean. </summary>
    # <parameter name="$1"> directory </parameter>
    # <returns> boolean </returns>
    function CreateDirReturnBool
    {
        local bool=false

        if [[ $( CheckIfDirIsNotNullReturnBool $1 ) == false ]]; then
            bool=true
            mkdir -p $1 &> /dev/null || bool=false
        fi

        echo $bool
    }

    # <summary> Create file, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CreateFileReturnBool
    {
        local bool=false

        if [[ $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
            touch $1 &> /dev/null || bool=false
        fi

        echo $bool
    }

    # <summary> Delete file, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function DeleteFileReturnBool
    {
        local bool=false

        if [[ $( CheckIfFileExistsReturnBool $1 ) == true ]]; then
            bool=true
            rm $1 &> /dev/null || bool=false
        fi

        echo $bool
    }

    # <summary> Redirect to script directory. </summary>
    # <returns> boolean </returns>
    function GoToScriptDirectoryReturnBool
    {
        local bool=false
        declare -lr str_dir=$( dirname $0 )

        if [[ $( CheckIfDirIsNotNullReturnBool $str_dir ) == true ]]; then
            bool=true
            cd $str_dir || bool=false
        fi

        echo $bool
    }

    # <summary> Ask for Yes/No answer, return boolean.  If input is not valid, return false. </summary>
    # <parameter name="$1" name="$var_return"> boolean return value </parameter>
    # <parameter name="$2"> nullable output statement </parameter>
    # <returns> $var_return </returns>
    function ReadInputReturnBool
    {
        # <parameters> #
        local bool=false
        declare -il int_count=0
        declare -lir int_maxCount=3
        declare -lr str_output=$2
        # </parameters> #

        while [[ $int_count -le $int_maxCount ]]; do
            # <summary> After given number of attempts, input is set to default: false. </summary>
            if [[ $int_count -ge $int_maxCount ]]; then
                var_return="N"
                echo -en "Exceeded max attempts. Default selection: \e[30;42m$var_return\e[0m"
                break
            fi

            if [[ $( CheckIfVarIsNotNullReturnBool $str_output ) == true ]]; then
                echo -n "$str_output "
            fi

            # <summary> Append output. </summary>
            echo -en "\e[30;43m[Y/n]:\e[0m "
            read var_return
            declare -l var_return=$var_return
            var_return=$( echo $var_return | tr '[:lower:]' '[:upper:]' )

            # <summary> Check if string is a valid input. </summary>
            case $var_return in
                "Y")
                    bool=true; break;;
                "N")
                    break;;
            esac

            # <summary> Input is invalid, increment counter. </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        # <summary> Return value. </summary>
        var_return=$bool
    }

    # <summary> Ask for multiple choice, up to eight choices. Ignore case.  If input is not valid, return first choice. </summary>
    # <parameter name="$var_return"> number return value </parameter>
    # <parameter name="$1"> nullable output statement </parameter>
    # <parameter name="$2"> multiple choice </parameter>
    # <parameter name="$3"> multiple choice </parameter>
    # <parameter name="$4"> multiple choice </parameter>
    # <parameter name="$5"> multiple choice </parameter>
    # <parameter name="$6"> multiple choice </parameter>
    # <parameter name="$7"> multiple choice </parameter>
    # <parameter name="$8"> multiple choice </parameter>
    # <parameter name="$9"> multiple choice </parameter>
    # <returns> $var_return </returns>
    function ReadInputFromMultipleChoiceUpperCase
    {
        # <parameters> #
        declare -i int_count=0
        declare -ir int_maxCount=3
        declare -r str_output=$1
        declare -ru var_input1=$2
        declare -ru var_input2=$3
        declare -ru var_input3=$4
        declare -ru var_input4=$5
        declare -ru var_input5=$6
        declare -ru var_input6=$7
        declare -ru var_input7=$8
        declare -ru var_input8=$9
        # </parameters> #

        # <summary> It's not multiple choice if there aren't two or more choices; Input validation is not necessary here. </summary>
        if [[
            $( CheckIfVarIsNotNullReturnBool $var_input1 ) == false
            || $( CheckIfVarIsNotNullReturnBool $var_input2 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input3 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input4 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input5 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input6 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input7 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $var_input8 ) == false
            ]]; then
            var_return=""

        # <summary> Prompt user for input. </summary>
        else
            while [[ $int_count -le $int_maxCount ]]; do
                # <summary> After given number of attempts, input is set to default: first choice. </summary>
                if [[ $int_count -ge $int_maxCount ]]; then
                    var_return="$var_input1"
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$var_input1\e[0m"
                    break
                fi

                # <summary> Append output. </summary>
                if [[ $( CheckIfVarIsNotNullReturnBool $str_output ) == true ]]; then
                    echo -en "$str_output "
                fi

                read var_return
                declare -u var_return=$var_return

                # <summary> Check if string is a valid input. </summary>
                case $var_return in
                    $var_input1|$var_input2|$var_input3|$var_input4|$var_input5|$var_input6|$var_input7|$var_input8)
                        break;
                esac

                # <summary> Input is invalid, increment counter. </summary>
                echo -en "\e[33mInvalid input.\e[0m "
                (( int_count++ ))
            done
        fi
    }

    # <summary> Ask for multiple choice, up to eight choices. Match exact case. If input is not valid, return first choice. </summary>
    # <parameter name="$var_return"> number return value </parameter>
    # <parameter name="$1"> nullable output statement </parameter>
    # <parameter name="$2"> multiple choice </parameter>
    # <parameter name="$3"> multiple choice </parameter>
    # <parameter name="$4"> multiple choice </parameter>
    # <parameter name="$5"> multiple choice </parameter>
    # <parameter name="$6"> multiple choice </parameter>
    # <parameter name="$7"> multiple choice </parameter>
    # <parameter name="$8"> multiple choice </parameter>
    # <parameter name="$9"> multiple choice </parameter>
    # <returns> $var_return </returns>
    function ReadInputFromMultipleChoiceMatchCase
    {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=3
        declare -lr str_output=$1
        # </parameters> #

        # <summary> It's not multiple choice if there aren't two or more choices; Input validation is not necessary here. </summary>
        if [[
            $( CheckIfVarIsNotNullReturnBool $2 ) == false
            || $( CheckIfVarIsNotNullReturnBool $3 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $4 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $5 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $6 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $7 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $8 ) == false
            # || $( CheckIfVarIsNotNullReturnBool $9 ) == false
            ]]; then
            var_return=""

        # <summary> Prompt user for input. </summary>
        else
            while [[ $int_count -le $int_maxCount  ]]; do
                # <summary> After given number of attempts, input is set to default: first choice. </summary>
                if [[ $int_count -ge $int_maxCount ]]; then
                    var_return="$2"
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$2\e[0m"
                    break
                fi

                # <summary> Append output. </summary>
                if [[ $( CheckIfVarIsNotNullReturnBool $str_output ) == true ]]; then
                    echo -en "$str_output "
                fi

                read var_return

                # <summary> Check if string is a valid input. </summary>
                case $var_return in
                    $2|$3|$4|$5|$6|$7|$8|$9)
                        break;
                esac

                # <summary> Input is invalid, increment counter. </summary>
                echo -en "\e[33mInvalid input.\e[0m "
                (( int_count++ ))
            done
        fi
    }

    # <summary> Ask for a number, within a given range, and return a number. If input is not valid, return minimum value. </summary>
    # <parameter name="$var_return"> number return value </parameter>
    # <parameter name="$1"> absolute minimum </parameter>
    # <parameter name="$2"> absolute maximum </parameter>
    # <parameter name="$3"> nullable output statement </parameter>
    # <returns> $var_return </returns>
    function ReadInputFromRangeOfNums
    {
        # <parameters> #
        declare -i int_count=0
        declare -ir int_maxCount=3
        declare -ir int_max=$2
        declare -ir int_min=$1
        declare -r str_output=$3
        # </parameters> #

        # <summary> Return null value if either extrema are not valid. </summary>
        if [[
            $( CheckIfVarIsValidNumReturnBool $int_min ) == false
            && $( CheckIfVarIsValidNumReturnBool $int_max ) == false
            ]]; then
            var_return=""

        # <summary> Prompt user for input. </summary>
        else
            while [[ $int_count -le $int_maxCount ]]; do
                # <summary> After given number of attempts, input is set to default: minimum. </summary>
                if [[ $int_count -ge $int_maxCount ]]; then
                    echo -en "Exceeded max attempts. Default selection: \e[30;42m$int_min\e[0m"
                    var_return="$int_min"
                    break
                fi

                # <summary> Append output. </summary>
                if [[ $( CheckIfVarIsNotNullReturnBool $str_output ) == true ]]; then
                    echo -n "$str_output "
                fi

                echo -en "\e[30;43m[Y/n]:\e[0m "
                read var_return

                # <summary> Check if string is a valid number and within given range. </summary>
                if [[
                    $var_return -ge $int_min
                    && $var_return -le $int_max
                    && $( CheckIfVarIsValidNumReturnBool $var_return ) == true
                    ]]; then
                    break
                fi

                # <summary> Input is invalid, increment counter. </summary>
                echo -en "\e[33mInvalid input.\e[0m "
                (( int_count++ ))
            done
        fi
    }

    # <summary> Overwrite file with array, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array </parameter>
    # <returns> boolean </returns>
    function OverwriteArrayToFileReturnBool
    {
        declare -lr IFS=$'\n'
        local bool=false

        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            bool=true
            local -n arr_file1="$2"
            ( printf "%s\n" "${arr_file1[@]}" > $1 || bool=false ) &> /dev/null
        fi

        echo $bool
    }

    # <summary> Overwrite file with string, and return boolean. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> boolean </returns>
    function OverwriteVarToFileReturnBool
    {
        local bool=false

        if [[ $( CheckIfVarIsNotNullReturnBool $2 ) == true ]]; then
            bool=true
            ( echo -e $2 > $1 || bool=false ) &> /dev/null
        fi

        echo $bool
    }
# </code>

# <summary> File operation logic with exit codes. </summary>
# <code>
    # <summary> Output statement. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array </parameter>
    # <returns> void </returns>
    function AppendArrayToFileReturnExitCode
    {
        echo -en "Writing to file '$1'...\t"
        declare lr bool=$( AppendArrayToFileReturnBool $1 $2 )

        # <summary> Set exit code. </summary>
        if [[ $bool == false ]]; then
            SetExitCodeIfFileIsNotWritable
        fi
    }

    # <summary> Output statement. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> void </returns>
    function AppendVarToFileReturnExitCode
    {
        echo -en "Writing to file '$1'...\t"
        declare lr bool=$( AppendVarToFileReturnBool $1 $2 )

        # <summary> Set exit code. </summary>
        if [[ $bool == false ]]; then
            SetExitCodeIfFileIsNotWritable
        fi
    }

    # <summary> Output statement. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> file </parameter>
    # <returns> void </returns>
    function CheckIfTwoFilesAreSameReturnExitCode
    {
        echo -en "Verifying two files...\t"
        declare lr bool=$( CheckIfTwoFilesAreSameReturnBool $1 $2 )

        if [[ $bool == true ]]; then
            echo -e 'Positive Match.\n\t"%s"\n\t"%s"' "$1" "$2"
            true
        else
            echo -e 'False Match.\n\t"%s"\n\t"%s"' "$1" "$2"
            false
        fi
    }

    # <summary> Output statement. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array </parameter>
    # <returns> void </returns>
    function OverwriteArrayToFileReturnExitCode
    {
        echo -en "Writing to file '$1'...\t"
        declare lr bool=$( OverwriteArrayToFileReturnBool $1 $2 )

        # <summary> Set exit code. </summary>
        if [[ $bool == false ]]; then
            SetExitCodeIfFileIsNotWritable
        fi
    }

    # <summary> Output statement. If false, set exit code. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> void </returns>
    function OverwriteVarToFileReturnExitCode
    {
        echo -en "Writing to file '$1'...\t"
        declare lr bool=$( OverwriteVarToFileReturnBool $1 $2 )

        # <summary> Set exit code. </summary>
        if [[ $bool == false ]]; then
            SetExitCodeIfFileIsNotWritable
        fi
    }
# </code>
###

### program functions ###
# <summary> Logic specific to the purpose of this program or repository. </summary>
# <code>
    # <summary> Crontab </summary>
    # <returns> void </returns>
    function AppendCron
    {
        echo -e "Appending cron entries..."

        # <parameters>
        declare -lr str_dir1="/etc/cron.d/"

        # <summary>
        # List of packages that have cron files (see below).
        # NOTE: May change depend on content of cron files (ex: simple, common commands that are not from given specific packages, i.e "cp" or "rm").
        # </summary>
        declare -a arr_requiredPackages=(
            "flatpak"
            "ntpdate"
            "rsync"
            "snap"
        )

        if [[ $( command -v unattended-upgrades ) == "" ]]; then
            arr_requiredPackages+=("apt")
        fi
        # </parameters>

        GoToScriptDirectoryReturnBool &> /dev/null
        # <summary> Set working directory to script root folder. </summary>
        CheckIfDirIsNotNullReturnBool $str_filesDir &> /dev/null
        cd $str_filesDir &> /dev/null || ( false; SaveThisExitCode )


        if [[ $int_exitCode -eq 0 ]]; then
            for var_element1 in $( ls *-cron ); do
                ReadInput "Append '${var_element1}'?"

                if [[ $int_exitCode -eq 0 ]]; then
                    for var_element2 in ${arr_requiredPackages[@]}; do

                        # <summary>
                        # Match given cron file, append only if package exists in system.
                        # </summary>
                        if [[ ${var_element1} == *"${var_element2}"* ]]; then
                            if [[ $( command -v ${var_element2} ) != "" ]]; then
                                cp $var_element1 ${str_dir1}${var_element1}
                                # echo -e "Appended file '${var_element1}'."
                            else
                                echo -e "\e${str_warning}Missing required package '${var_element2}'. Skipping..."
                            fi
                        fi
                    done
                fi
            done
        fi

        # <summary> Restart service. </summary>
        if [[ $int_exitCode -eq 0 ]]; then
            systemctl enable cron &> /dev/null || ( false; SaveThisExitCode )
            systemctl restart cron &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode "Appending cron entries..."; ParseThisExitCode; echo
    }

    # <summary> Append SystemD services to host. </summary>
    # <returns> void </returns>
    function AppendServices
    {
        echo -e "Appending files to Systemd..."

        # <parameters>
        declare -lr str_pattern=".service"
        declare -alr arr_dir1=( $( ls | uniq | grep -Ev ${str_pattern} ) )
        declare -alr arr_dir2=( $( ls | uniq | grep ${str_pattern} ))
        # </parameters>

        # <summary> Copy files and set permissions. </summary>
        function AppendServices_AppendFile
        {
            CheckIfFileExistsReturnBool $2 &> /dev/null

            while [[ $int_exitCode -eq 0 ]]; do
                cp $1 $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                chown root $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                chmod +x $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                break
            done
        }

        # <summary> Set working directory to script root folder. </summary>
        CheckIfDirIsNotNullReturnBool $str_filesDir &> /dev/null
        cd $str_filesDir &> /dev/null || ( false; SaveThisExitCode )


        if [[ $int_exitCode -eq 0 ]]; then
            # <summary> Copy binaries to system. </summary>
            for var_element1 in ${arr_dir1[@]}; do
                local str_file1="/usr/sbin/${var_element1}"
                AppendServices_AppendFile $var_element1 $str_file1
            done

            # <summary> Copy services to system. </summary>
            for var_element1 in ${arr_dir2[@]}; do
                # <parameters>
                local str_file1="/etc/systemd/system/${var_element1}"
                # </parameters>

                AppendServices_AppendFile $var_element1 $str_file1

                if [[ $int_exitCode -eq 0 ]]; then
                    systemctl daemon-reload &> /dev/null || ( SetExitCodeOnError; SaveThisExitCode )
                    ReadInput "Enable/disable '${var_element1}'?"

                    case $int_exitCode in
                        0)
                            systemctl enable ${var_element1} &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode );;
                        *)
                            systemctl disable ${var_element1} &> /dev/null;;
                    esac
                fi
            done

            systemctl daemon-reload &> /dev/null || ( SetExitCodeOnError; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode "Appending files to Systemd..."; ParseThisExitCode; echo
    }

    # <summary> Check if Linux distribution is Debian or Debian-derivative. </summary>
    # <returns> boolean </returns>
    function CheckCurrentDistro
    {
        if [[ $( CheckIfCommandExistsReturnBool "apt" ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            echo -e "${str_warning}Unrecognized Linux distribution; Apt not installed. Skipping..."
        fi

        echo $bool
    }

    # <summary> Clone given GitHub repositories. </summary>
    # <returns> void </returns>
    function CloneOrUpdateGitRepositories
    {
        echo -e "Cloning Git repos..."

        # <parameters>
        declare -l bool_gitCloneHasFailed=false
        # </parameters>

        # <summary> sudo/root v. user </summary>
        if [[ $bool_isUserRoot == true ]]; then
            # <parameters>
            declare -lr str_dir1="/root/source/"

            # <summary>
            # List of useful Git repositories.
            # Example: "username/reponame"
            # </summary>
            declare -alr arr_repo=(
                "corna/me_cleaner"
                "dt-zero/me_cleaner"
                "foundObjects/zram-swap"
                "portellam/Auto-Xorg"
                "portellam/deploy-VFIO-setup"
                "pyllyukko/user.js"
                "StevenBlack/hosts"
            )
            # </parameters>
        else
            # <parameters>
            declare -lr str_dir1=$( echo ~/ )"source/"

            # <summary>
            # List of useful Git repositories.
            # Example: "username/reponame"
            # </summary>
            declare -alr arr_repo=(
                "awilliam/rom-parser"
                #"pixelplanetdev/4chan-flag-filter"
                #"pyllyukko/user.js"
                "SpaceinvaderOne/Dump_GPU_vBIOS"
                "spheenik/vfio-isolate"
            )
            # </parameters>
        fi

        CreateDirReturnBool $str_dir1 &> /dev/null
        chmod -R +w $str_dir1 &> /dev/null

        if [[ $( CheckIfFileIsWritableReturnBool $str_dir1 ) == true ]]; then
            for str_repo in ${arr_repo[@]}; do
                cd $str_dir1

                # <parameters>
                local str_userName=$( echo $str_repo | cut -d "/" -f1 )
                # </parameters>

                CreateDirReturnBool ${str_dir1}${str_userName} &> /dev/null

                # <summary> Update existing GitHub repository. </summary>
                if [[ $( CheckIfDirIsNotNullReturnBool ${str_dir1}${str_repo} ) == true ]]; then
                    cd ${str_dir1}${str_repo}
                    git pull &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )

                # <summary> Clone new GitHub repository. </summary>
                else
                    ReadInput "Clone repo '$str_repo'?"

                    if [[ $int_exitCode -eq 0 ]]; then
                        cd ${str_dir1}${str_userName}
                        git clone https://github.com/$str_repo || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                        echo
                    fi
                fi

                # <summary> Save status of operations and reset exit code. </summary>
                if [[ $int_exitCode -eq 131 ]]; then
                    bool_gitCloneHasFailed=true
                fi

                true; SaveThisExitCode
            done
        fi

        if [[ $bool_gitCloneHasFailed == true ]]; then
            SetExitCodeIfPassNorFail; SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode "Cloning Git repos..."; ParseThisExitCode

        if [[ $bool_gitCloneHasFailed == true ]]; then
            echo -e "One or more Git repositories were not cloned."
        fi

        echo
    }

    # <summary> Install necessary commands/packages for this program. </summary>
    # <returns> void </returns>
    function InstallCommands
    {
        echo -en "Checking for commands... "

        # <summary> Install a given command, return boolean. </summary>
        # <parameter name="$1"> command_to_use </parameter>
        # <parameter name="$2"> required_packages </parameter>
        # <returns> boolean </returns>
        function InstallCommands_InstallThisCommandReturnBoolean
        {
            local bool=false

            if [[
                $( CheckIfVarIsNotNullReturnBool $1 ) == true
                && $( CheckIfVarIsNotNullReturnBool $2 ) == true
                && $( CheckIfCommandExistsReturnBool $1 ) == false
                ]]; then
                bool=true
                apt install -y $2 &> /dev/null || bool=false
            fi

            if [[ $( CheckIfCommandExistsReturnBool $1 ) == true ]]; then
                bool=true
            fi

            echo $bool
        }

        TestNetwork &> /dev/null

        if [[ $( CheckCurrentDistro ) == true ]]; then
            bool_is_xmllint_installed=$( InstallCommands_InstallThisCommandReturnBoolean "xmllint" "xml-core xmlstarlet" )

            # InstallThisCommand "command_to_use" "required_packages"
            # boolean_to_set=$( ParseThisExitCodeAsBool )
        else
            false
        fi

        EchoPassOrFailThisExitCode;
        # ParseThisExitCode;
        echo
    }

    # <summary> Install from Debian repositories. </summary>
    # <returns> void </returns>
    function InstallFromDebianRepos
    {
        # <parameters>
        local str_args=""
        local var_return=false
        # </parameters>

        echo -e "Installing from $( lsb_release -is ) $( uname -o ) repositories..."
        ReadInputReturnBool $var_return "Auto-accept install prompts? "

        if [[ $var_return == true ]]; then
            str_args="-y"
        fi

        # <summary> Update and upgrade local packages </summary>
        apt clean
        apt update

        # <summary> Desktop environment checks </summary>
        # <parameters>
        local str_aptCheck=""
        str_aptCheck=$( apt list --installed plasma-desktop lxqt )      # Qt DE (KDE-plasma, LXQT)
        # </parameters>

        if [[ $str_aptCheck != "" ]]; then
            apt install -y plasma-discover-backend-flatpak
        fi

        # <parameters>
        str_aptCheck=""
        str_aptCheck=$( apt list --installed gnome xfwm4 )              # GNOME DE (gnome, XFCE)
        # </parameters>

        if [[ $( CheckIfVarIsNotNullReturnBool $str_aptCheck ) == true ]]; then
            apt install -y gnome-software-plugin-flatpak
        fi

        echo    # output padding

        # <summary> APT packages sorted by type. </summary>
        # <parameters>
        local str_aptAll=""
        declare -lr str_aptDeveloper=""
        declare -lr str_aptDrivers="steam-devices"
        declare -lr str_aptGames=""
        declare -lr str_aptInternet="firefox-esr filezilla"
        declare -lr str_aptMedia="vlc"
        declare -lr str_aptOffice="libreoffice"
        declare -lr str_aptPrismBreak=""
        declare -lr str_aptSecurity="apt-listchanges bsd-mailx fail2ban gufw ssh ufw unattended-upgrades"
        declare -lr str_aptSuites="debian-edu-install science-all"
        declare -lr str_aptTools="apcupsd bleachbit cockpit curl flashrom git grub-customizer java-common lm-sensors neofetch python3 qemu rtl-sdr synaptic unzip virt-manager wget wine youtube-dl zram-tools"
        declare -lr str_aptUnsorted=""
        declare -lr str_aptVGAdrivers="nvidia-detect xserver-xorg-video-all xserver-xorg-video-amdgpu xserver-xorg-video-ati xserver-xorg-video-cirrus xserver-xorg-video-fbdev xserver-xorg-video-glide xserver-xorg-video-intel xserver-xorg-video-ivtv-dbg xserver-xorg-video-ivtv xserver-xorg-video-mach64 xserver-xorg-video-mga xserver-xorg-video-neomagic xserver-xorg-video-nouveau xserver-xorg-video-openchrome xserver-xorg-video-qxl/ xserver-xorg-video-r128 xserver-xorg-video-radeon xserver-xorg-video-savage xserver-xorg-video-siliconmotion xserver-xorg-video-sisusb xserver-xorg-video-tdfx xserver-xorg-video-trident xserver-xorg-video-vesa xserver-xorg-video-vmware"
        # </parameters>

        # <summary> Select and Install software sorted by type. </summary>
        function InstallFromDebianRepos_InstallByType
        {
            if [[ $( CheckIfVarIsNotNullReturnBool $1 ) == true ]]; then
                # <parameters>
                local var_return=false
                # </parameters>

                echo -e $2

                if [[ $1 == *" "* ]]; then
                    declare -il int_i=1

                    while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                        echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                        (( int_i++ ))                                   # counter
                    done
                else
                    echo -e "\t$1"
                fi

                ReadInputReturnBool $var_return

                if [[ $var_return == true ]]; then
                    str_aptAll+="$1 "
                fi

                echo    # output padding
            fi
        }

        InstallFromDebianRepos_InstallByType $str_aptUnsorted "Select given software?"
        InstallFromDebianRepos_InstallByType $str_aptDeveloper "Select Development software?"
        InstallFromDebianRepos_InstallByType $str_aptGames "Select games?"
        InstallFromDebianRepos_InstallByType $str_aptInternet "Select Internet software?"
        InstallFromDebianRepos_InstallByType $str_aptMedia "Select multi-media software?"
        InstallFromDebianRepos_InstallByType $str_aptOffice "Select office software?"
        InstallFromDebianRepos_InstallByType $str_aptPrismBreak "Select recommended \"Prism break\" software?"
        InstallFromDebianRepos_InstallByType $str_aptSecurity "Select security tools?"
        InstallFromDebianRepos_InstallByType $str_aptSuites "Select software suites?"
        InstallFromDebianRepos_InstallByType $str_aptTools "Select software tools?"
        InstallFromDebianRepos_InstallByType $str_aptVGAdrivers "Select VGA drivers?"

        if [[ $( CheckIfVarIsNotNullReturnBool $str_aptAll ) == true ]]; then
            apt install $str_args $str_aptAll
        fi

        # <summary> Clean up </summary>
        apt autoremove $str_args
        EchoPassOrFailThisExitCode "Installing from $( lsb_release -is ) $( uname -o ) repositories..."; ParseThisExitCode
    }

    # NOTE: fixed Debian function, need to update other functions that call "ReadInputReturnBoolean"

    # <summary> Install from Flathub software repositories. </summary>
    # <returns> void </returns>
    function InstallFromFlathubRepos
    {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary> Flatpak </summary>
        if [[ $( CheckIfCommandExistsReturnBool "flatpak" ) == true ]]; then
            echo -e "${str_warning}Flatpak not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_exitCode" in
                0)
                    local str_args="-y";;
                *)
                    local str_args="";;
            esac

            # <summary> Add remote repository. </summary>
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

            # <summary> Update local packages. </summary>
            flatpak update $str_args
            echo    # output padding

            # <summary> Flatpak packages sorted by type. </summary>
            # <parameters>
            local str_flatpakAll=""
            declare -lr str_flatpakUnsorted="com.adobe.Flash-Player-Projector com.calibre_ebook.calibre com.makemkv.MakeMKV com.obsproject.Studio com.poweriso.PowerISO com.stremio.Stremio com.valvesoftware.Steam com.valvesoftware.SteamLink com.visualstudio.code com.vscodium.codium fr.handbrake.ghb io.github.Hexchat io.gitlab.librewolf-community nz.mega.MEGAsync org.bunkus.mkvtoolnix-gui org.filezillaproject.Filezilla org.freedesktop.LinuxAudio.Plugins.TAP org.freedesktop.LinuxAudio.Plugins.swh org.freedesktop.Platform org.freedesktop.Platform.Compat.i386 org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL.default org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL32.nvidia-460-91-03 org.freedesktop.Platform.VAAPI.Intel.i386 org.freedesktop.Platform.ffmpeg-full org.freedesktop.Platform.openh264 org.freedesktop.Sdk org.getmonero.Monero org.gnome.Platform org.gtk.Gtk3theme.Breeze org.kde.KStyle.Adwaita org.kde.Platform org.kde.digikam org.kde.kdenlive org.keepassxc.KeePassXC org.libreoffice.LibreOffice org.mozilla.Thunderbird org.openshot.OpenShot org.videolan.VLC org.videolan.VLC.Plugin.makemkv org.libretro.RetroArch"
            declare -lr str_flatpakPrismBreak="" # include from all, monero etc.
            # </parameters>

            # <summary> Select and Install software sorted by type. </summary>
            # <code>
                function InstallFromFlathubRepos_InstallByType
                {
                    if [[ $1 != "" ]]; then
                        echo -e $2

                        if [[ $1 == *" "* ]]; then
                            declare -il int_i=1

                            while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                                echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                                (( int_i++ ))                                   # counter
                            done
                        else
                            echo -e "\t$1"
                        fi

                        ReadInput

                        if [[ $int_exitCode -eq 0 ]]; then
                            str_flatpakAll+="$1 "
                        fi

                        echo    # output padding
                    fi
                }

                InstallFromFlathubRepos_InstallByType $str_flatpakUnsorted "Select given Flatpak software?"
                InstallFromFlathubRepos_InstallByType $str_flatpakPrismBreak "Select recommended Prism Break Flatpak software?"

                if [[ $str_flatpakAll != "" ]]; then
                    echo -e "Install selected Flatpak apps?"
                    apt install $str_args $str_aptAll
                fi
            # </code>
        fi

        EchoPassOrFailThisExitCode "Installing from alternative $( uname -o ) repositories..."; ParseThisExitCode; echo
    }

    # <summary> Install from Git repositories. </summary>
    # <returns> void </returns>
    function InstallFromGitRepos
    {
        echo -e "Executing Git scripts..."

        # <summary> Prompt user to execute script or skip. </summary>
        function ExecuteScript
        {
            # <parameters>
            # local str_dir2=$( echo "$1" | awk -F'/' '{print $1"/"$2}' )
            local str_dir2=$( basename $1 )"/"
            # </parameters>

            if [[ $( CheckIfDirIsNotNullReturnBool $1 ) == true ]]; then
                cd $1
            fi

            if [[ $( CheckIfFileExistsReturnBool $2 ) == true ]]; then
                ReadInput "Execute script '${str_dir2}$2'?"
                chmod +x $2 &> /dev/null

                if [[ $int_exitCode -eq 0 && $( CheckIfFileIsExecutableReturnBool $2 ) == true ]]; then
                    # <summary> sudo/root v. user </summary>
                    if [[ $bool_isUserRoot == true ]]; then
                        sudo bash $2 || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                    else
                        bash $2 || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                    fi

                    cd $str_dir1
                fi
            fi

            # <summary> Save status of operations and reset exit code. </summary>
            if [[ $int_exitCode -eq 131 ]]; then
                bool_gitCloneHasFailed=true
            fi

            true; SaveThisExitCode; echo
        }

        # <parameters>
        declare -l bool_execHasFailed=false

        # <summary> sudo/root v. user </summary>
        if [[ $bool_isUserRoot == true ]]; then
            declare -lr str_dir1="/root/source/"
        else
            declare -lr str_dir1="~/source/"
        fi
        # </parameters>

        # <summary> Test this on a fresh install </summary>
        if [[ $( CheckIfDirIsNotNullReturnBool $str_dir1 ) == true ]]; then

            # <summary> sudo/root v. user </summary>
            if [[ $bool_isUserRoot == true ]]; then

                # <summary> portellam/Auto-Xorg </summary>
                local str_file1="installer.bash"
                local str_repo="portellam/auto-xorg"
                local str_scriptDir="${str_dir1}${str_repo}/"
                ExecuteScript $str_scriptDir $str_file1

                # <summary> StevenBlack/hosts </summary>
                local str_repo="stevenblack/hosts"
                local str_scriptDir="${str_dir1}${str_repo}/"
                echo -e "Executing script '${str_repo}'"

                if [[ $( CheckIfDirIsNotNullReturnBool $str_scriptDir ) == true ]]; then
                    cd $str_scriptDir
                    local str_file1="/etc/hosts"

                    if [[ $( CreateBackupFromFileReturnBool $str_file1 ) == true ]]; then
                        cp hosts $str_file1 &> /dev/null || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                    fi
                fi

                # <summary> pyllyukko/user.js </summary>
                local str_repo="pyllyukko/user.js"
                local str_scriptDir="${str_dir1}${str_repo}/"
                echo -e "Executing script '${str_repo}'"

                if [[ $( CheckIfDirIsNotNullReturnBool $str_scriptDir ) == true ]]; then
                    cd $str_scriptDir
                    local str_file1="/etc/firefox-esr/firefox-esr.js"

                    make debian_locked.js &> /dev/null && (
                        if [[ $( CreateBackupFromFileReturnBool $str_file1 ) == true ]]; then
                            cp debian_locked.js $str_file1 &> /dev/null || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                        fi
                    )
                fi

                # <summary> foundObjects/zram-swap </summary>
                local str_file1="installer.sh"
                local str_repo="foundObjects/zram-swap"
                local str_scriptDir="${str_dir1}${str_repo}/"
                ExecuteScript $str_scriptDir $str_file1
            else

                # <summary> awilliam/rom-parser </summary>
                # local str_file1="installer.sh"
                local str_repo="awilliam/rom-parser"
                local str_scriptDir="${str_dir1}${str_repo}/"
                # ExecuteScript $str_scriptDir $str_file1
                # CheckIfDirIsNotNullReturnBool $str_scriptDir

                # <summary> spaceinvaderone/Dump_GPU_vBIOS </summary>
                # local str_file1="installer.sh"
                local str_repo="spaceinvaderone/dump_gpu_vbios"
                local str_scriptDir="${str_dir1}${str_repo}/"
                # ExecuteScript $str_scriptDir $str_file1
                # CheckIfDirIsNotNullReturnBool $str_scriptDir

                # <summary> spheenik/vfio-isolate </summary>
                # local str_file1="installer.sh"
                local str_repo="spheenik/vfio-isolate"
                local str_scriptDir="${str_dir1}${str_repo}/"
                # ExecuteScript $str_scriptDir $str_file1
                # CheckIfDirIsNotNullReturnBool $str_scriptDir
            fi
        fi

        if [[ $bool_execHasFailed == true ]]; then
            SetExitCodeIfPassNorFail; SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode "Executing Git scripts..."; ParseThisExitCode

        if [[ $bool_execHasFailed == true ]]; then
            echo -e "One or more Git scripts were not executed."
        fi

        echo
    }

    # <summary> Install from Snap software repositories. </summary>
    # <returns> void </returns>
    function InstallFromSnapRepos
    {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary> Snap </summary>
        if [[ $( command -v snap ) != "/usr/bin/snap" ]]; then
            echo -e "${str_warning}Snap not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_exitCode" in
                0)
                    local str_args="-y";;
                *)
                    local str_args="";;
            esac

            # <summary> Update local packages. </summary>
            flatpak update $str_args
            echo    # output padding

            # <summary> Snap packages sorted by type. </summary>
            # <parameters>
            local str_snapAll=""
            declare -lr str_snapUnsorted=""
            # </parameters>

            # <summary> Select and Install software sorted by type. </summary>
            # <code>
                function InstallFromSnapRepos_InstallByType
                {
                    if [[ $1 != "" ]]; then
                        echo -e $2

                        if [[ $1 == *" "* ]]; then
                            declare -il int_i=1

                            while [[ $( echo $1 | cut -d ' ' -f$int_i ) ]]; do
                                echo -e "\t"$( echo $1 | cut -d ' ' -f$int_i )
                                (( int_i++ ))                                   # counter
                            done
                        else
                            echo -e "\t$1"
                        fi

                        ReadInput

                        if [[ $int_exitCode -eq 0 ]]; then
                            str_snapAll+="$1 "
                        fi

                        echo    # output padding
                    fi
                }

                InstallFromSnapRepos_InstallByType $str_snapUnsorted "Select given Snap software?"

                if [[ $str_snapAll != "" ]]; then
                    echo -e "Install selected Snap apps?"
                    apt install $str_args $str_snapAll
                fi
            # </code>
        fi

        EchoPassOrFailThisExitCode "Installing from alternative $( uname -o ) repositories..."; ParseThisExitCode; echo
    }

    # <summary> Setup software repositories for Debian Linux. </summary>
    # <returns> void </returns>
    function ModifyDebianRepos
    {
        IFS=$'\n'

        echo -e "Modifying $( lsb_release -is ) $( uname -o ) repositories..."

        # <parameters>
        declare -lr str_file1="/etc/apt/sources.list"
        local str_sources=""
        declare -lr str_newFile1="${str_file1}.new"
        declare -lr str_releaseName=$( lsb_release -sc )
        declare -lr str_releaseVer=$( lsb_release -sr )
        # </parameters>

        # <summary> Create backup or restore from backup. </summary>
        if [[ $( CreateBackupFromFileReturnBool $str_file1 ) == true ]]; then
            while [[ $int_exitCode -eq 0 ]]; do
                ReadInput "Include 'contrib' sources?"
                str_sources+="contrib"
                break
            done

            true; SaveThisExitCode

            # <summary> Setup optional sources. </summary>
            while [[ $int_exitCode -eq 0 ]]; do
                ReadInput "Include 'non-free' sources?"
                str_sources+=" non-free"
                break
            done
        fi

        true; SaveThisExitCode

        # <summary> Setup mandatory sources. </summary>
        # <summary> User prompt </summary>
        echo
        echo -e "Repositories: Enter one valid option or none for default (Current branch: ${str_releaseName})."
        echo -e "${str_warning}It is NOT possible to revert from a non-stable branch back to a stable or ${str_releaseName} release branch."
        echo -e "Release branches:"
        echo -e "\t'stable'\t== '${str_releaseName}'"
        echo -e "\t'testing'\t*more recent updates; slightly less stability"
        echo -e "\t'unstable'\t*most recent updates; least stability. NOT recommended."
        echo -e "\t'backports'\t== '${str_releaseName}-backports'\t*optionally receive more recent updates."

        # <summary Apt sources </summary>
        # <parameters>
        local var_return=""
        ReadInputFromMultipleChoiceMatchCase "Enter option: " "stable" "testing" "unstable" "backports"
        declare -lr str_branchName=$var_return

        declare -al arr_sources=(
            "# debian $str_branchName"
            "# See https://wiki.debian.org/SourcesList for more information."
            "deb http://deb.debian.org/debian/ $str_branchName main $str_sources"
            "deb-src http://deb.debian.org/debian/ $str_branchName main $str_sources"
            $'\n'
            "deb http://deb.debian.org/debian/ $str_branchName-updates main $str_sources"
            "deb-src http://deb.debian.org/debian/ $str_branchName-updates main $str_sources"
            $'\n'
            "deb http://security.debian.org/debian-security/ $str_branchName-security main $str_sources"
            "deb-src http://security.debian.org/debian-security/ $str_branchName-security main $str_sources"
            "#"
        )
        # </parameters>

        # <summary> Write to file. </summary>
        if [[ $( CheckIfFileExistsReturnBool $str_file1 ) == true ]]; then
            declare -al arr_file1=()

            while read var_element1; do
                if [[ $var_element1 != "#"* ]]; then
                    var_element1="#$var_element1"
                fi

                arr_file1+=( $var_element1 )
            done < $str_file1

            # for var_element1 in ${arr_file1[@]}; do
            #     # AppendVarToFileReturnBool $str_file1 $var_element1 &> /dev/null
            #     ( echo -e $var_element1 >> $str_file1 ) &> /dev/null || ( false; SaveThisExitCode )
            # done
        fi

        # <summary> Append to output. </summary>
        case $str_branchName in
            # <summary> Current branch with backports. </summary>
            "backports")
                declare -al arr_sources=(
                    "# debian $str_releaseVer/$str_releaseName"
                    "# See https://wiki.debian.org/SourcesList for more information."
                    "deb http://deb.debian.org/debian/ $str_releaseName main $str_sources"
                    "deb-src http://deb.debian.org/debian/ $str_releaseName main $str_sources"
                    ""
                    "deb http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
                    "deb-src http://deb.debian.org/debian/ $str_releaseName-updates main $str_sources"
                    ""
                    "deb http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
                    "deb-src http://security.debian.org/debian-security/ $str_releaseName-security main $str_sources"
                    "#"
                    ""
                    "# debian $str_releaseVer/$str_releaseName $str_branchName"
                    "deb http://deb.debian.org/debian $str_releaseName-$str_branchName main contrib non-free"
                    "deb-src http://deb.debian.org/debian $str_releaseName-$str_branchName main contrib non-free"
                    "#"
                );;
        esac

        # <summary> Output to sources file. </summary>
        declare -lr str_file2="/etc/apt/sources.list.d/$str_branchName.list"
        DeleteFileReturnBool $str_file2 &> /dev/null
        CreateFileReturnBool $str_file2 &> /dev/null

        case $str_branchName in
            "backports"|"testing"|"unstable")
                printf "%s\n" "${arr_sources[@]}" > $str_file2 &> /dev/null
                SaveThisExitCode
                ;;
        esac

        # <summary> Update packages on system. </summary>
        while [[ $int_exitCode -eq 0 ]]; do
            apt clean || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            apt update || ( SetExitCodeOnError; SaveThisExitCode )
            apt full-upgrade || ( SetExitCodeOnError; SaveThisExitCode )
            break
        done

        EchoPassOrFailThisExitCode "Modifying $( lsb_release -is ) $( uname -o ) repositories..."; ParseThisExitCode; echo
    }

    # <summary> Configuration of SSH. </summary>
    # <returns> void </returns>
    function ModifySSH
    {
        # <summary> Exit if command is not present. </summary>
        if [[ $( CheckIfCommandExistsReturnBool "ssh" ) == true ]]; then
            false; SaveThisExitCode
            echo -e "${str_warning}SSH not installed! Skipping..."
        fi

        # <summary> Prompt user to enter alternate valid IP port value for SSH. </summary>
        while [[ $int_exitCode -eq 0 ]]; do
            ReadInput "Modify SSH?"

            # <parameters>
            declare -il int_count=0
            # </parameters>

            while [[ $int_count -lt 3 ]]; do
                # <parameters>
                local str_altSSH=$( ReadInputFromRangeOfNums "\tEnter a new IP Port number for SSH (leave blank for default):" 22 65536 )
                declare -il int_altSSH="${str_altSSH}"
                # </parameters>

                if [[ $int_altSSH -eq 22 || $int_altSSH -gt 10000 ]]; then
                    break
                fi

                SetExitCodeIfInputIsInvalid; SaveThisExitCode
                echo -e "${str_warning}Available port range: 1000-65535"
                ((int_count++))
            done

            break
        done

        # <summary> Write to system files. </summary>
        if [[ $int_exitCode -eq 0 ]]; then
            # <parameters>
            declare -lr str_file1="/etc/ssh/ssh_config"
            # declare -lr str_file2="/etc/ssh/sshd_config"
            declare -lr str_output1="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"
            # </parameters>

            if [[ (
                $( CheckIfFileExistsReturnBool $str_file1 ) == true
                && $( CreateBackupFromFileReturnBool $str_file1 ) == true
                && $( AppendVarToFileReturnBool $str_file1 $str_output1 ) == true
                && $( CheckIfFileExistsReturnBool $str_file1 ) == true
                ) ]]; then

                systemctl restart ssh || ( false; SaveThisExitCode )
            fi

            # if [[ (
            #     $( CheckIfFileExistsReturnBool $str_file2 ) == true
            #     && $( CreateBackupFromFileReturnBool $str_file2 ) == true
            #     && $( AppendVarToFileReturnBool $str_file2 $str_output1 ) == true
            #     && $( CheckIfFileExistsReturnBool $str_file2 ) == true
            #     ) ]]; then

            #     systemctl restart sshd || ( false; SaveThisExitCode )
            # fi
        fi
    }

    # <summary> Recommended host security changes. </summary>
    # <returns> void </returns>
    function ModifySecurity
    {
        echo -e "Configuring system security..."

        # <parameters>
        local bool=false
        # str_packagesToRemove="atftpd nis rsh-redone-server rsh-server telnetd tftpd tftpd-hpa xinetd yp-tools"
        declare -lr arr_files1=(
            "/etc/modprobe.d/disable-usb-storage.conf"
            "/etc/modprobe.d/disable-firewire.conf"
            "/etc/modprobe.d/disable-thunderbolt.conf"
        )
        declare -lr str_services="acpupsd cockpit fail2ban ssh ufw"     # include services to enable OR disable: cockpit, ssh, some/all packages installed that are a security-risk or benefit.
        # </parameters>

        # <summary> Set working directory to script root folder. </summary>
        bool=$( CheckIfDirIsNotNullReturnBool $str_filesDir )
        ( cd $str_filesDir || bool=false ) &> /dev/null

        # <summary> Write output to files. </summary>
        if [[ $bool == true ]]; then
            ReadInput "Disable given device interfaces (for storage devices only): USB, Firewire, Thunderbolt?"

            # <summary> Yes. </summary>
            if [[ $int_exitCode -eq 0 && (
                $( DeleteFileReturnBool ${arr_files1[0]} ) == true
                && $( AppendVarToFileReturnBool ${arr_files1[0]} 'install usb-storage /bin/true' ) == true
                && $( DeleteFileReturnBool ${arr_files1[1]} ) == true
                && $( AppendVarToFileReturnBool ${arr_files1[1]} 'blacklist firewire-core' ) == true
                && $( DeleteFileReturnBool ${arr_files1[2]} ) == true
                && $( AppendVarToFileReturnBool ${arr_files1[2]} 'blacklist thunderbolt' ) == true
            ) ]]; then
                bool=true
                update-initramfs -u -k all || bool=false

            # <summary> No, delete any changes and update system. </summary>
            else
                for var_element1 in ${arr_files1}; do
                    bool=$( DeleteFileReturnBool ${arr_files1[0]} )
                done

                if [[ $bool == true ]]; then
                    update-initramfs -u -k all || bool=false
                fi
            fi
        fi

        if [[ $bool == true ]]; then
            echo -e "${str_warning}Failed to make changes."
        fi

        # <summary> Write output to files. </summary>
        local str_file1="sysctl.conf"
        local str_file2="/etc/sysctl.conf"

        # fix here

        if [[ $( CheckIfFileExistsReturnBool $str_file1 ) == true ]]; then
            ReadInput "Setup '/etc/sysctl.conf' with defaults?"

            if [[ $int_exitCode -eq 0 && (
                ! ( cp $str_file1 $str_file2 )
                || ! (cat $str_file2 >> $str_file1 )
                ) ]]; then
                SetExitCodeIfPassNorFail; SaveThisExitCode
            fi
        done

        ReadInput "Setup firewall with UFW?"

        if [[ $int_exitCode -eq 0 ]]; then
            bool=$( CheckIfCommandExistsReturnBool "ufw" )

            if [[ $bool == false ]]; then
                echo -e "${str_warning}UFW is not installed. Skipping..."
            fi

            if [[ $bool == true && (
                ! $( ufw reset )
                && ! $( ufw default allow outgoing )
                && ! $( ufw default deny incoming )
                ) ]]; then
                bool=false
            fi

            # <summary> Default LAN subnets may be 192.168.1.0/24 </summary>
            # <summary> Services a desktop may use. Attempt to make changes. Exit early at failure. </summary>
            if [[ $bool == true && (
                ! $( ufw allow DNS comment 'dns' &> /dev/null )
                && ! $( ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server' &> /dev/null )
                && ! $( ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server' &> /dev/null )
                && ! $( ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server' &> /dev/null )
                && ! $( ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server' &> /dev/null )
                && ! $( ufw allow VNC comment 'VNC, local remote desktop server' &> /dev/null )
                && ! $( ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server' &> /dev/null )
                ) ]]; then
                bool=false
            fi

            # <summary> Services a server may use. Attempt to make changes. Exit early at failure. </summary>
            if [[ $bool == true && (
                ! $( ufw allow http comment 'HTTP, local Web server' &> /dev/null )
                && ! $( ufw allow https comment 'HTTPS, local Web server' &> /dev/null )
                && ! $( ufw allow 25 comment 'SMTPD, local mail server' &> /dev/null )
                && ! $( ufw allow 110 comment 'POP3, local mail server' &> /dev/null )
                && ! $( ufw allow 995 comment 'POP3S, local mail server' &> /dev/null )
                && ! $( ufw allow 1194/udp 'SMTPD, local VPN server' &> /dev/null )
                ) ]]; then
                bool=false
            fi

            # <summary> SSH on LAN </summary>
            if [[ $( CheckIfCommandExistsReturnBool "ssh" ) == false ]]; then
                echo -e "${str_warning}SSH is not installed. Skipping..."
            else
                local var_return=""
                ModifySSH $var_return
                declare -lr bool_altSSH=$( CheckIfVarIsValidNumReturnBool ${str_altSSH} )

                # <summary> If alternate choice is provided, attempt to make changes. Exit early at failure. </summary>
                if [[ $bool == true && (
                    ! $( ufw deny ssh comment 'deny default ssh' &> /dev/null )
                    || ! $( ufw limit from 192.168.0.0/16 to any port ${str_sshAlt} proto tcp comment 'ssh' &> /dev/null )
                    ) ]]; then
                    SetExitCodeIfPassNorFail; SaveThisExitCode
                fi

                # <summary> If alternate choice is not provided, attempt to make changes. Exit early at failure. </summary>
                if [[ $bool == false && (
                    ! $( ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh' &> /dev/null )
                    ) ]]; then
                    SetExitCodeIfPassNorFail; SaveThisExitCode
                fi

                if [[ ! $( ufw deny ssh comment 'deny default ssh' &> /dev/null ) ]]; then
                    SetExitCodeIfPassNorFail; SaveThisExitCode
                fi
            fi

            # <summary> Do not save changes. </summary>
            if [[ $bool == false ]]; then
                SetExitCodeIfPassNorFail; SaveThisExitCode
            fi

            # <summary> Attempt to save changes. Exit early at failure. </summary>
            if [[
                ! $( ufw enable &> /dev/null )
                || ! $( ufw reload &> /dev/null )
                ]]; then
                false; SaveThisExitCode
            fi
        fi

        EchoPassOrFailThisExitCode "Configuring system security..."; ParseThisExitCode; echo
    }
# </code>
###

### main functions ###
# <summary> Middleman logic between Program logic and Main code. </summary>
# <code>
    # <summary> Display Help to console. </summary>
    # <returns> void </returns>
    function Help
    {                                 # NOTE: needs work.
        declare -r str_helpPrompt="Usage: $0 [ OPTIONS ]
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

    # <summary> Parse input parameters for given options. </summary>
    # <returns> void </returns>
    function ParseInputParamForOptions
    {            # NOTE: needs work.
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

    # <summary> Execute setup of recommended and optional system changes. </summary>
    # <returns> void </returns>
    function ExecuteSystemSetup
    {
        # ModifySecurity
        # ModifySSH
        AppendServices
        # AppendCron
    }

    # <summary> Execute setup of all software repositories. </summary>
    # <returns> void </returns>
    function ExecuteSetupOfSoftwareSources
    {
        if [[ $( CheckCurrentDistro ) == true ]]; then
            ModifyDebianRepos
            TestNetwork &> /dev/null

            if [[ $int_exitCode -eq 0 ]]; then
                InstallFromDebianRepos
                InstallFromFlathubRepos
                InstallFromSnapRepos
            fi
        fi

        echo -e "\n${str_warning}If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
    }

    # <summary> Execute setup of GitHub repositories (of which that are executable and installable). </summary>
    # <returns> void </returns>
    function ExecuteSetupOfGitRepos
    {
        if [[ $( CheckIfCommandExistsReturnBool "git" ) == true ]]; then
            TestNetwork &> /dev/null

            if [[ $int_exitCode -eq 0 ]]; then
                CloneOrUpdateGitRepositories
            fi

            InstallFromGitRepos
        else
            echo -e "\n${str_warning}Git is not installed on this system."
        fi
    }
# </code>
###

### global parameters ###
# <summary> Variables to be used throughout the program. </summary>
# <code>
    declare -gr str_filesDir=$( dirname $( find .. -name files | uniq | head -n1 ) )
    declare -gr str_warning="\e[33mWARNING:\e[0m"" "

    # <summary> Necessary for exit code preservation, for conditional statements. </summary>
    declare -gi int_exitCode=$?

    # <summary> Checks </summary>
    declare -gr bool_isUserRoot=$( CheckIfUserIsRootReturnBool )
    declare -g bool_is_xmllint_installed=$( CheckIfCommandExistsReturnBool "xmllint" )
# </code>
###

### main ###
# <summary> If you need to a summary to describe this code-block's purpose, you're not gonna make it. </summary>
# <code>
    # <summary> Pre-execution checks. </summary>
    # InstallCommands &> /dev/null

    # <summary> Execute specific functions if user is sudo/root or not. </summary>
    if [[ $bool_isUserRoot == true ]]; then
        ExecuteSetupOfSoftwareSources
        # ExecuteSetupOfGitRepos
        # ExecuteSystemSetup
    else
        ExecuteSetupOfGitRepos
    fi

    # <summary> Post-execution clean up. </summary>
    ExitWithThisExitCode
# </code>
###