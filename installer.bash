#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

### notes ###
# <summary>
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

    # <summary> Output pass or fail statement given exit code. </summary>
    # <parameter name="$1"> string </parameter>
    # <returns> string </returns>
    function EchoPassOrFailThisExitCode
    {
        # while [[ $int_thisExitCode -eq 0 ]]; do
        #     CheckIfVarIsNull $1 &> /dev/null
        #     echo -en "$1 "
        #     break
        # done

        if [[ $( CheckIfVarIsNull $1 ) == true ]]; then
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

    # <summary> Output pass or fail test-case given exit code. </summary>
    # <parameter name="$1"> string </parameter>
    # <returns> string </returns>
    function EchoPassOrFailThisTestCase
    {
        # CheckIfVarIsNull $1 &> /dev/null
        # local str_testCaseName="TestCase"

        # if [[ $int_thisExitCode -eq 0 ]]; then
        #     str_testCaseName=$1
        # fi

        # readonly str_testCaseName

        if [[ $( CheckIfVarIsNull $1 ) == true ]]; then
            declare -lr str_testCaseName="TestCase"
        else
            declare -lr str_testCaseName=$1
        fi

        echo -en "$str_testCaseName "

        case "$int_thisExitCode" in
            0)
                echo -e "\e[32mPASS:\e[0m""\t$str_testCaseName";;
            *)
                echo -e " \e[33mFAIL:\e[0m""\t$str_testCaseName";;
        esac
    }

    # <summary> Exit bash session/script with current exit code. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> void </returns>
    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }

    # <summary> Output error given exception. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> void </returns>
    function ParseThisExitCode
    {
        case $int_thisExitCode in
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
    }

    # <summary> Updates global parameter. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> void </returns>
    function SaveThisExitCode
    {
        int_thisExitCode=$?
    }

    # <summary> Parse exit code as boolean. </summary>
    # <parameter name="$?"> exit code </parameter>
    # <returns> boolean </returns>
    function ParseThisExitCodeAsBoolean
    {
        if [[ $int_thisExitCode -eq 0 ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
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

### validation functions ###
# <summary> Validation logic </summary>
# <code>
    # <summary> Checks if command is installed, and set exit code if false. </summary>
    # <parameter name="$1"> command name </parameter>
    # <returns> boolean </returns>
    function CheckIfCommandIsInstalled
    {
        if [[ $( command -v $1 ) != "" ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            false; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary>
    # Checks if directory exists, and set exit code if false. </summary>
    # <parameter name="$1"> directory </parameter>
    # <returns> boolean </returns>
    function CheckIfDirIsNull
    {
        if [[ -d $1 && $( CheckIfVarIsNull $1 ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if file is executable, and set exit code if false. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsExecutable
    {
        if [[ -x $1 && $( CheckIfFileIsNull $1 ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfFileIsNotExecutable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if file exists, and set exit code if false. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsNull
    {
        if [[ -e $1 && $( CheckIfVarIsNull $1 ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfFileOrDirIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if file is readable, and set exit code if false. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsReadable
    {
        if [[ -r $1 && $( CheckIfFileIsNull $1 ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfFileIsNotReadable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if file is writable, and set exit code if false. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> boolean </returns>
    function CheckIfFileIsWritable
    {
        if [[ -w $1 && $( CheckIfFileIsNull $1 ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfFileIsNotWritable; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if current user is sudo/root, and set exit code if false. </summary>
    # <parameter name="$0"> file </parameter>
    # <returns> exit code </returns>
    function CheckIfUserIsRoot
    {
        if [[ $( whoami ) != "root" ]]; then
            echo -en "${str_warning}Script must execute as root."

            # while [[ $int_thisExitCode -eq 0 ]]; do
            #     CheckIfFileIsNull $0 &> /dev/null
            #     declare -lr str_file1=$( basename $0 )
            #     echo -e " In terminal, run:\n\t'sudo bash ${str_file1}'"
            #     break
            # done

            if [[ $( CheckIfFileIsNull $0 ) == false ]]; then
                declare -lr str_file1=$( basename $0 )
                echo -e " In terminal, run:\n\t'sudo bash ${str_file1}'"
            fi

            false; SaveThisExitCode
        fi

        echo
    }

    # <summary> Checks if input parameter is null, and set exit code if false. </summary>
    # <parameter name="$1"> variable </parameter>
    # <returns> boolean </returns>
    function CheckIfVarIsNull
    {
        if [[ ! -z "$1" ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfVarIsNull; SaveThisExitCode
        fi

        echo $bool
    }

    # <summary> Checks if input parameter is a valid number, and set exit code if false. </summary>
    # <parameter name="$1"> number variable </parameter>
    # <returns> boolean </returns>
    function CheckIfVarIsValidNum
    {
        if [[ "$1" -eq "$(( $1 ))" ]] 2> /dev/null; then
            declare -lr bool=true
        else
            declare -lr bool=false
            SetExitCodeIfInputIsInvalid; SaveThisExitCode
        fi

        echo $bool
    }
# </code>

### general functions ###
# <summary> File operation logic </summary>
# <code>
    # <summary> Append file with contents of array. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array of string </parameter>
    # <returns> exit code </returns>
    function AppendArrayToFile
    {
        declare -lr IFS=$'\n'
        echo -en "Writing to file..."

        if [[ $( CheckIfFileIsReadable $1 ) == true && $( CheckIfVarIsNull $2 ) == true ]]; then
            local -n arr_file1="$2"

            for var_element1 in ${arr_file1[@]}; do
                ( echo -e $var_element1 >> $1 ) &> /dev/null || ( false; SaveThisExitCode )
            done
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Append file with contents of variable. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> exit code </returns>
    function AppendVarToFile
    {
        declare -lr IFS=$'\n'
        echo -en "Writing to file..."

        if [[ $( CheckIfFileIsReadable $1 ) == true && $( CheckIfVarIsNull $2 ) == true ]]; then
            ( echo -e $2 >> $1 ) &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Change ownership of given file to current user. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> exit code </returns>
    function ChangeOwnershipOfFileOrDirToCurrentUser
    {
        if [[ $( CheckIfFileIsNull $1 ) == true ]]; then
            chown -f $UID $1 || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Checks if two given files are the same, in composition. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> file </parameter>
    # <returns> exit code </returns>
    function CheckIfTwoFilesAreSame
    {
        echo -e "Verifying two files..."

        if [[ $( CheckIfFileIsReadable $1 ) == true && $( CheckIfFileIsReadable $2 ) == true ]]; then
            if cmp -s "$1" "$2"; then
                echo -e 'Positive Match.\n\t"%s"\n\t"%s"' "$1" "$2"
            else
                echo -e 'False Match.\n\t"%s"\n\t"%s"' "$1" "$2"
                false; SaveThisExitCode
            fi
        fi

        ParseThisExitCode
    }

    # <summary> Checks if two given files are the same, in composition. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> exit code </returns>
    function CreateBackupFromFile
    {
        echo -en "Backing up file..."
        declare -lr str_file1=$1

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfFileIsReadable $str_file1 &> /dev/null

            # <parameters>
            declare -lr str_suffix=".old"
            declare -lr str_dir1=$( dirname $1 )
            declare -alr arr_dir1=( $( ls -1v $str_dir | grep $str_file1 | grep $str_suffix | uniq ) )
            # </parameters>

            if [[ "${#arr_dir1[@]}" -eq 0 ]]; then
                cp $str_file1 "${str_file1}.0${str_suffix}" &> /dev/null || ( false; SaveThisExitCode )
            else
                # <parameters>
                declare -ir int_maxCount=5
                local var_element1=${arr_dir1[0]}
                var_element1=${var_element1%"${str_suffix}"}             # substitution
                var_element1=${var_element1##*.}                         # ditto
                # </parameters>

                CheckIfVarIsValidNum $var_element1 &> /dev/null

                for var_element1 in ${arr_dir1[@]}; do
                    CheckIfTwoFilesAreSame $str_file1 $var_element1 &> /dev/null
                done

                # <summary>
                # Before backup, delete all but some number of backup files.
                # </summary>
                while [[ ${#arr_dir1[@]} -ge $int_maxCount ]]; do
                    if [[ -e ${arr_dir1[0]} ]]; then
                        DeleteFile ${arr_dir1[0]} &> /dev/null
                        break
                    fi
                done

                # <summary>
                # If *first* backup is same as original file, exit.
                # </summary>
                if cmp -s $1 ${arr_dir[0]}; then
                    false; SaveThisExitCode
                fi

                # <parameters>
                var_element1=${arr_dir1[-1]%"${str_suffix}"}            # substitution
                var_element1=${var_element1##*.}                        # ditto
                declare -il int_lastIndex=0
                # </parameters>

                CheckIfVarIsValidNum $var_element1 &> /dev/null
                declare -i int_lastIndex="${var_element1}"
                (( int_lastIndex++ ))                                   # counter

                # <summary> Source file is newer and different than backup, add to backups. </summary>
                if [[ $str_file1 -nt ${arr_dir1[-1]} && ! ( $str_file1 -ef ${arr_dir1[-1]} ) ]]; then
                    cp $str_file1 "${str_file1}.${int_lastIndex}${str_suffix}" &> /dev/null || ( false; SaveThisExitCode )
                fi
            fi

            break
        done

        EchoPassOrFailThisExitCode; ParseThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "No changes from most recent backup."
        fi
    }

    # <summary> Creates a directory. </summary>
    # <parameter name="$1"> directory </parameter>
    # <returns> exit code </returns>
    function CreateDir
    {
        echo -en "Creating directory..."

        if [[ $( CheckIfFileIsNull $1 ) == true ]]; then
            mkdir -p $1 &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Creates a file. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> exit code </returns>
    function CreateFile
    {
        echo -en "Creating file..."

        if [[ $( CheckIfFileIsNull $1 ) == true ]]; then
            touch $1 &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Deletes a file. </summary>
    # <parameter name="$1"> file </parameter>
    # <returns> exit code </returns>
    function DeleteFile
    {
        echo -en "Deleting file..."

        if [[ $( CheckIfFileIsNull $1 ) == true ]]; then
            rm $1 &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Redirect to script directory. </summary>
    # <parameter name="$str_thisDir"> directory </parameter>
    # <returns> exit code </returns>
    function GoToScriptDirectory
    {
        if [[ $( CheckIfDirIsNull $1 ) == true ]]; then
            cd $str_thisDir || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary> Reads a file. </summary>
    # <parameter name="$1"> array of string </parameter>
    # <parameter name="$2"> file </parameter>
    # <returns> array of string </returns>
    function ReadFile
    {
        echo -en "Reading file..."

        if [[ $( CheckIfVarIsNull $1 ) == true && $( CheckIfFileIsReadable $2 ) == true ]]; then
            local -n arr_file1="$1"
            readonly arr_file1=( $( cat $2 ) ) &> /dev/null || ( SetExitCodeIfFileIsNotReadable; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }

    # <summary>
    # Ask for Yes/No answer, return exit code.
    # Default selection is N/false.
    # </summary>
    # <returns> exit code </returns>
    function ReadInput
    {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -l str_output1=""

        if [[ $( CheckIfVarIsNull $1 ) == true ]]; then
            readonly str_output1="$1 "
        fi
        # </parameters> #

        true; SaveThisExitCode

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary> After given number of attempts, input is set to default: false. </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="N"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "${str_output1}\e[30;43m[Y/n]:\e[0m "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            # <summary> Check if string is a valid input. </summary>
            case $str_input1 in
                "Y")
                    break;;
                "N")
                    false; SaveThisExitCode; break;;
            esac

            # <summary> Input is invalid, increment counter. </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        echo
    }

    # <summary>
    # Ask for multiple choice, up to eight choices.
    # Default selection is first choice.
    # </summary>
    # <returns> string </returns>
    function ReadInputFromMultipleChoiceIgnoreCase
    {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -l str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            readonly str_output1="$1 "
        fi
        # </parameters> #

        CheckIfVarIsNull $2 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary>
            # After given number of attempts, input is set to default: false.
            # </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="$2"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "$str_output1"
            read str_input1

            # <summary>
            # Check if string is a valid input.
            # </summary>
            case $str_input1 in
                $2|$3|$4|$5|$6|$7|$8|$9)
                    true; SaveThisExitCode; break;
            esac

            # <summary>
            # Input is invalid, increment counter.
            # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        # <summary> Return value with stdout. </summary>
        CheckIfVarIsNull $str_input1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo $str_input1
        fi
    }

    # <summary>
    # Ask for multiple choice, up to eight choices.
    # Default selection is first choice.
    # </summary>
    # <returns> string </returns>
    function ReadInputFromMultipleChoiceUpperCase
    {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -l str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            readonly str_output1="$1 "
        fi
        # </parameters> #

        CheckIfVarIsNull $2 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary> After given number of attempts, input is set to default: false. </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1="$2"
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                false; SaveThisExitCode; break
            fi

            echo -en "$str_output1"
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            # <summary> Check if string is a valid input. </summary>
            case $str_input1 in
                $2|$3|$4|$5|$6|$7|$8|$9)
                    true; SaveThisExitCode; break;
            esac

            # <summary> Input is invalid, increment counter. # </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        # <summary> Return value with stdout. </summary>
        CheckIfVarIsNull $str_input1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo $str_input1
        fi
    }

    # <summary>
    # Ask for number, within a given range.
    # Default selection is first choice.
    # </summary>
    # <returns> int </returns>
    function ReadInputFromRangeOfNums
    {
        # <parameters> #
        declare -il int_count=0
        declare -lir int_maxCount=2
        declare -l str_output1=""

        if [[ $int_thisExitCode -eq 0 ]]; then
            readonly str_output1="$1 "
        fi
        # </parameters> #

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary> After given number of attempts, input is set to default: min value. </summary>
            if [[ $int_count -gt $int_maxCount ]]; then
                str_input1=$2
                echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                break
            fi

            echo -en "$str_output1"
            read str_input1

            # <summary> Check if string is a valid integer and within given range. </summary>
            if [[ $str_input1 -ge $2 && $str_input1 -le $3 && ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null; then
                break
            fi

            # <summary> Input is invalid, increment counter. </summary>
            echo -en "\e[33mInvalid input.\e[0m "
            (( int_count++ ))
        done

        # <summary> Return value with stdout. </summary>
        CheckIfVarIsNull $str_input1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo $str_input1
        fi
    }

    # <summary> Read from XML Data Object Module. </summary>
    # <returns> content variable </returns>
    # function ReadFromXMLDOM
    # {
    #     declare -lr IFS=$'\>'
    #     read -d \< $var_entity $var_content
    # }

    # <summary> Read from XML Data Object Module. </summary>
    # <returns> content variable </returns>
    # function ReadFromXMLFile
    # {
    #     declare -al arr_file1=()

    #     while ReadFromXMLDOM; do
    #         if [[ $var_entity = "title" ]]; then
    #             echo $var_content
    #             exit
    #         fi
    #     done < xhtmlfile.xhtml > titleOfXHTMLPage.txt
    # }

    # <summary> Reset IFS. </summary>
    # function SetInternalFieldSeparatorToDefault
    # {
    #     IFS=$var_IFS
    # }

    # <summary>
    # Backup IFS and Set IFS to newline char.
    # NOTE: necessary for newline preservation in arrays and files.
    # </summary>
    # function SetInternalFieldSeparatorToNewline
    # {
    #     var_IFS=$IFS
    #     IFS=$'\n'
    # }

    # <summary> Test network connection to Internet. Ping DNS servers by address and name. </summary>
    # <returns> exit code </returns>
    function TestNetwork
    {
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || ( false; SaveThisExitCode; )
        EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || ( false; SaveThisExitCode; )
        EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        EchoPassOrFailThisExitCode; echo
    }

    # <summary> Overwrite file with contents of array. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> array of string </parameter>
    # <returns> exit code </returns>
    # function OverwriteArrayToFile                                     # refactor or consolidate, this looks like shite
    # {
    #     echo -en "Writing to file..."

    #     DeleteFile $1 &> /dev/null

    #     # if [[ $int_thisExitCode -eq 0 ]]; then
    #     #     AppendArrayToFile $1 $2
    #     # fi

    #     if [[ $( DeleteFile $1 ) == true ]]; then
    #         AppendArrayToFile $1 $2
    #     fi
    # }

    # <summary> Overwrite file with contents of variable. </summary>
    # <parameter name="$1"> file </parameter>
    # <parameter name="$2"> string </parameter>
    # <returns> exit code </returns>
    function OverwriteVarToFile
    {
        declare -lr IFS=$'\n'
        echo -en "Writing to file..."

        while [[ $int_thisExitCode -eq 0 ]]; do
            CheckIfVarIsNull $1 &> /dev/null
            CheckIfVarIsNull $2 &> /dev/null
            CheckIfFileIsNull $1 &> /dev/null
            CheckIfFileIsReadable $1 &> /dev/null
            CheckIfFileIsWritable $1 &> /dev/null
            ( echo -e $2 > $1 ) &> /dev/null || ( false; SaveThisExitCode )
            break
        done

        if [[ $( DeleteFile $1 ) == true ]]; then
            AppendArrayToFile $1 $2
        fi

        EchoPassOrFailThisExitCode; ParseThisExitCode
    }
# </code>

### program functions ###
# <summary>
# Logic specific to the purpose of this program or repository.
# </summary>
# <code>
    # <summary> Crontab </summary>
    # <returns> exit code </returns>
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

        GoToScriptDirectory &> /dev/null
        # <summary> Set working directory to script root folder. </summary>
        CheckIfDirIsNull $str_filesDir &> /dev/null
        cd $str_filesDir &> /dev/null || ( false; SaveThisExitCode )


        if [[ $int_thisExitCode -eq 0 ]]; then
            for var_element1 in $( ls *-cron ); do
                ReadInput "Append '${var_element1}'?"

                if [[ $int_thisExitCode -eq 0 ]]; then
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
        if [[ $int_thisExitCode -eq 0 ]]; then
            systemctl enable cron &> /dev/null || ( false; SaveThisExitCode )
            systemctl restart cron &> /dev/null || ( false; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode "Appending cron entries..."; ParseThisExitCode
    }

    # <summary> Append SystemD services to host. </summary>
    # <returns> exit code </returns>
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
            CheckIfFileIsNull $2 &> /dev/null

            while [[ $int_thisExitCode -eq 0 ]]; do
                cp $1 $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                chown root $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                chmod +x $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                break
            done
        }

        # <summary> Set working directory to script root folder. </summary>
        CheckIfDirIsNull $str_filesDir &> /dev/null
        cd $str_filesDir &> /dev/null || ( false; SaveThisExitCode )


        if [[ $int_thisExitCode -eq 0 ]]; then
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

                if [[ $int_thisExitCode -eq 0 ]]; then
                    systemctl daemon-reload &> /dev/null || ( SetExitCodeOnError; SaveThisExitCode )
                    ReadInput "Enable/disable '${var_element1}'?"

                    case $int_thisExitCode in
                        0)
                            systemctl enable ${var_element1} &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode );;
                        *)
                            systemctl disable ${var_element1} &> /dev/null;;
                    esac
                fi
            done

            systemctl daemon-reload &> /dev/null || ( SetExitCodeOnError; SaveThisExitCode )
        fi

        EchoPassOrFailThisExitCode "Appending files to Systemd..."; ParseThisExitCode
    }

    # <summary> Check if Linux distribution is Debian or Debian-derivative. </summary>
    # <returns> boolean </returns>
    function CheckCurrentDistro
    {
        if [[ $( CheckIfCommandIsInstalled "apt" ) == true ]]; then
            declare -lr bool=true
        else
            declare -lr bool=false
            echo -e "${str_warning}Unrecognized Linux distribution; Apt not installed. Skipping..."
        fi

        echo $bool
    }

    # <summary> Clone given GitHub repositories. </summary>
    # <returns> exit code </returns>
    function CloneOrUpdateGitRepositories
    {
        echo -e "Cloning/Updating Git repos..."

        # <summary>
        # sudo/root v. user
        # List of useful Git repositories.
        # Example: "username/reponame"
        # </summary>
        # <parameters>
        if [[ $bool_isUserRoot == true ]]; then
            declare -lr str_dir1="/root/source/repos"
            declare -alr arr_repo=(
                "corna/me_cleaner"
                "dt-zero/me_cleaner"
                "foundObjects/zram-swap"
                "portellam/Auto-Xorg"
                "portellam/deploy-VFIO-setup"
                "pyllyukko/user.js"
                "StevenBlack/hosts"
            )
        else
            declare -lr str_dir1=$( echo ~/ )"source/repos"
            declare -alr arr_repo=(
                "awilliam/rom-parser"
                #"pixelplanetdev/4chan-flag-filter"
                "pyllyukko/user.js"
                "SpaceinvaderOne/Dump_GPU_vBIOS"
                "spheenik/vfio-isolate"
            )
        fi
        # </parameters>

        CreateDir $str_dir1 &> /dev/null
        # CheckIfFileIsWritable $str_dir1 &> /dev/null

        # if [[ $int_thisExitCode -eq 0 ]]; then
        if [[ $( CheckIfFileIsWritable $str_dir1 ) == true ]]; then
            for str_repo in ${arr_repo[@]}; do
                cd $str_dir1

                # <parameters>
                local str_userName=$( basename $str_repo )
                # </parameters>

                # CheckIfDirIsNull ${str_dir1}${str_userName} &> /dev/null

                # if [[ $int_thisExitCode -ne 0 ]]; then
                if [[ $( CheckIfDirIsNull ${str_dir1}${str_userName} ) == true  ]]; then
                    CreateDir ${str_dir1}${str_userName} &> /dev/null
                fi

                # CheckIfDirIsNull ${str_dir1}${str_repo} &> /dev/null

                # if [[ $int_thisExitCode -eq 0 ]]; then
                if [[ $( CheckIfDirIsNull ${str_dir1}${str_repo} ) == true  ]]; then
                    cd ${str_dir1}${str_repo}
                    git pull https://github.com/$str_repo
                else
                    ReadInput "Clone repo '$str_repo'?"

                    if [[ $int_thisExitCode -eq 0 ]]; then
                    # if [[ $( ReadInput "Clone repo '$str_repo'?" ) == true ]]; then                 # NOTE: will this work?
                        cd ${str_dir1}${str_userName}
                        git clone https://github.com/$str_repo || SetExitCodeIfPassNorFail
                    fi
                fi
            done
        fi

        SaveThisExitCode; EchoPassOrFailThisExitCode "Cloning/Updating Git repos..."; ParseThisExitCode

        if [[ $int_thisExitCode -eq 131 ]]; then
            echo -e "One or more Git repositories could not be cloned."
        fi
    }

    # <summary> Install necessary commands/packages for this program. </summary>
    # <returns> exit code </returns>
    function InstallCommands
    {
        echo -e "Checking for commands..."

        # <summary> Install a given command. </summary>
        # <parameter name="$1"> command_to_use </parameter>
        # <parameter name="$2"> required_packages </parameter>
        # <returns> exit code </returns>
        function InstallThisCommand
        {
            if [[ $( CheckIfVarIsNull $1 ) == true && $( CheckIfVarIsNull $2 ) == true && $( CheckIfCommandIsInstalled $1 ) == false ]]; then
                echo -en "Installing '$1'... "
                apt install -y $2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )

                if [[ $( CheckIfCommandIsInstalled $1 ) == false ]]; then
                    SetExitCodeIfPassNorFail; SaveThisExitCode
                fi

                EchoPassOrFailThisExitCode
            fi
        }

        TestNetwork &> /dev/null

        # if [[ $int_thisExitCode -eq 0 ]]; then
        if [[ $int_thisExitCode -eq 0 && $( CheckCurrentDistro ) == true ]]; then
            InstallThisCommand "xmllint" "xml-core xmlstarlet"
            bool_is_xmllint_installed=$( ParseThisExitCodeAsBoolean )

            # InstallThisCommand "command_to_use" "required_packages"
            # boolean_to_set=$( ParseThisExitCodeAsBoolean )
        else
            false; SaveThisExitCode
        fi

        EchoPassOrFailThisExitCode "Checking for commands..."; ParseThisExitCode
    }

    # <summary> Install from Debian repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromDebianRepos
    {
        echo -e "Installing from $( lsb_release -is ) $( uname -o ) repositories..."
        ReadInput "Auto-accept install prompts? "

        case "$int_thisExitCode" in
            0)
                local str_args="-y";;
            *)
                local str_args="";;
        esac

        # <summary> Update and upgrade local packages </summary>
        apt clean
        apt update

        # <summary> Desktop environment checks </summary>
        local str_aptCheck=""
        str_aptCheck=$( apt list --installed plasma-desktop lxqt )      # Qt DE (KDE-plasma, LXQT)

        if [[ $str_aptCheck != "" ]]; then
            apt install -y plasma-discover-backend-flatpak
        fi

        str_aptCheck=""
        str_aptCheck=$( apt list --installed gnome xfwm4 )              # GNOME DE (gnome, XFCE)

        if [[ $str_aptCheck != "" ]]; then
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

                if [[ $int_thisExitCode -eq 0 ]]; then
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

        if [[ $str_aptAll != "" ]]; then
            apt install $str_args $str_aptAll
        fi

        # <summary> Clean up </summary>
        apt autoremove $str_args
        EchoPassOrFailThisExitCode "Installing from $( lsb_release -is ) $( uname -o ) repositories..."; ParseThisExitCode
    }

    # <summary> Install from Flathub software repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromFlathubRepos
    {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary> Flatpak </summary>
        if [[ $( command -v flatpak ) != "/usr/bin/flatpak" ]]; then
            echo -e "${str_warning}Flatpak not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_thisExitCode" in
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

                        if [[ $int_thisExitCode -eq 0 ]]; then
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

        EchoPassOrFailThisExitCode "Installing from alternative $( uname -o ) repositories..."; ParseThisExitCode
    }

    # <summary> Install from Git repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromGitRepos
    {
        echo -e "Executing Git scripts..."

        # <summary> Prompt user to execute script or skip. </summary>
        function ExecuteScript
        {
            cd $str_dir1

            # <parameters>
            local str_dir2=$( echo "$1" | awk -F'/' '{print $1"/"$2}' )
            local str_script=$( basename $str_dir2 )
            # </parameters>

            if [[ $( CheckIfDirIsNull $str_script ) == true ]]; then
                ReadInput "Execute script '$str_script'?"

                if [[ $int_thisExitCode -eq 0 ]]; then
                    cd $str_dir2
                    CheckIfFileIsExecutable $str_script &> /dev/null

                    if [[ $( CheckIfFileIsExecutable $str_script ) == true ]]; then
                        bash $str_script || SetExitCodeIfPassNorFail
                    fi

                    cd $str_dir1
                fi
            fi
        }

        # <parameters>
        if [[ $bool_isUserRoot == true ]]; then
            declare -lr str_dir1="/root/source/repos"
        else
            declare -lr str_dir1="~/source/repos"
        fi
        # </parameters>

        CreateDir $str_dir1 &> /dev/null

        if [[ $( CheckIfFileIsWritable $str_dir1 ) == true ]]; then
            if [[ $bool_isUserRoot == true ]]; then
                # <summary>
                # portellam/Auto-Xorg
                # Install system service from repository.
                # Finds first available non-VFIO VGA/GPU and binds to Xorg.
                # </summary>
                local str_scriptDir="portellam/Auto-Xorg/installer.bash"
                ExecuteScript $str_scriptDir

                # <summary> StevenBlack/hosts </summary>
                local str_scriptDir="StevenBlack/hosts"

                if [[ $( CheckIfDirIsNull $str_scriptDir ) == true ]]; then
                    cd $str_scriptDir
                    local str_file1="/etc/hosts"

                    if [[ $( CreateBackupFromFile $str_file1 ) == true ]]; then
                        cp hosts $str_file1 || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                    fi

                    cd $str_dir1
                fi

                # <summary> pyllyukko/user.js </summary>
                local str_scriptDir="pyllyukko/user.js"
                CheckIfDirIsNull $str_scriptDir

                if [[ $( CheckIfDirIsNull $str_scriptDir ) == true ]]; then
                    cd $str_scriptDir
                    local str_file1="/etc/firefox-esr/firefox-esr.js"

                    make debian_locked.js && (
                        if [[ $( CreateBackupFromFile $str_file1 ) == true ]]; then
                            cp debian_locked.js $str_file1 &> /dev/null || ( SetExitCodeIfPassNorFail && SaveThisExitCode )
                        fi
                    )
                    cd $str_dir1
                fi

                # <summary> foundObjects/zram-swap </summary>
                local str_scriptDir="foundObjects/zram-swap/install.sh"
                ExecuteScript $str_scriptDir
            fi
        fi

        EchoPassOrFailThisExitCode "Executing Git scripts..."; ParseThisExitCode
    }

    # <summary> Install from Snap software repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromSnapRepos
    {
        echo -e "Installing from alternative $( uname -o ) repositories..."

        # <summary> Snap </summary>
        if [[ $( command -v snap ) != "/usr/bin/snap" ]]; then
            echo -e "${str_warning}Snap not installed. Skipping..."
            false; SaveThisExitCode
        else
            ReadInput "Auto-accept install prompts? "

            case "$int_thisExitCode" in
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

                        if [[ $int_thisExitCode -eq 0 ]]; then
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

        EchoPassOrFailThisExitCode "Installing from alternative $( uname -o ) repositories..."; ParseThisExitCode
    }

    # <summary> Setup software repositories for Debian Linux. </summary>
    # <returns> exit code </returns>
    function ModifyDebianRepos
    {
        echo -e "Modifying $( lsb_release -is ) $( uname -o ) repositories..."

        # <parameters>
        declare -lr str_file1="/etc/apt/sources.list"
        local str_sources=""
        declare -lr str_newFile1="${str_file1}.new"
        declare -lr str_releaseName=$( lsb_release -sc )
        declare -lr str_releaseVer=$( lsb_release -sr )
        # </parameters>

        # <summary> Create backup or restore from backup. </summary>
        CheckIfFileIsNull $str_file1 &> /dev/null

        if [[ $int_thisExitCode -eq 0 ]]; then
            CreateBackupFromFile $str_file1
        fi

        # <summary> Setup optional sources. </summary>
        while [[ $int_thisExitCode -eq 0  ]]; do
            ReadInput "Include 'contrib' sources?"
            str_sources+="contrib"
            break
        done

        while [[ $int_thisExitCode -eq 0  ]]; do
            ReadInput "Include 'non-free' sources?"
            str_sources+=" non-free"
            break
        done

        # <summary> Setup mandatory sources. </summary>
        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary> User prompt </summary>
            echo -e "Repositories: Enter one valid option or none for default (Current branch: ${str_releaseName})."
            echo -e "\t\n${str_warning}It is NOT possible to revert from a Non-stable branch back to a Stable or ${str_releaseName} branch."
            echo -e "\tRelease branches:"
            echo -e "\t\t'stable'\t== '${str_releaseName}'"
            echo -e "\t\t'testing'\t*more recent updates, slightly less stability"
            echo -e "\t\t'unstable'\t*most recent updates, least stability. NOT recommended."
            echo -e "\t\t'backports'\t== '${str_releaseName}-backports'\t*optionally receive more recent updates."

            # <summary Apt sources </summary>
            # <parameters>
            declare -lr str_branchName=$( ReadInputFromMultipleChoiceIgnoreCase "\tEnter option: " "stable" "testing" "unstable" "backports" )
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

            # <summary> Copy lines from original to temp file as comments. </summary>
            DeleteFile $str_newFile1 &> /dev/null
            CreateFile $str_newFile1 &> /dev/null

            while read var_element1; do
                if [[ $var_element1 != "#"* ]]; then
                    var_element1="#$var_element1"
                fi

                AppendVarToFile $str_newFile1 $var_element1
            done < $str_file1

            DeleteFile $str_newFile1 &> /dev/null
            mv $str_newFile1 $str_file1 &> /dev/null || ( false; SaveThisExitCode )

            # <summary> Append to output. </summary>
            case $str_branchName in
                # <summary> Current branch with backports. </summary>
                "backports")
                    declare -al arr_sources=(
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
                    break;;
            esac

            # <summary> Output to sources file. </summary>
            case $str_branchName in
                "backports"|"testing"|"unstable")
                    while read var_element1; do
                        var_element1=${arr_sources[$int_i]}
                        AppendVarToFile "/etc/apt/sources.list.d/'$str_input2'.list" $var_element1
                    done < $str_file1;;
                *)
                    echo -e "\e[33mInvalid input.\e[0m";;
            esac

            DeleteFile $str_newFile1 &> /dev/null
            break
        done

        # <summary> Update packages on system. </summary>
        while [[ $int_thisExitCode -eq 0 ]]; do
            apt clean || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            apt update || ( SetExitCodeOnError; SaveThisExitCode )
            apt full-upgrade || ( SetExitCodeOnError; SaveThisExitCode )
            break
        done

        EchoPassOrFailThisExitCode "Modifying $( lsb_release -is ) $( uname -o ) repositories..."; ParseThisExitCode
    }

    # <summary> Configuration of SSH. </summary>
    # <returns> exit code </returns>
    function ModifySSH
    {
        # <summary> Exit if command is not present. </summary>
        if [[ $( command -v ssh ) == "" ]]; then
            false; SaveThisExitCode
            echo -e "${str_warning}SSH not installed! Skipping..."
        fi

        # <summary> Prompt user to enter alternate valid IP port value for SSH. </summary>
        while [[ $int_thisExitCode -eq 0 ]]; do
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
        if [[ $int_thisExitCode -eq 0 ]]; then
            # <parameters>
            declare -lr str_file1="/etc/ssh/ssh_config"
            # declare -lr str_file2="/etc/ssh/sshd_config"
            declare -lr str_output1="\nLoginGraceTime 1m\nPermitRootLogin prohibit-password\nMaxAuthTries 6\nMaxSessions 2"
            # </parameters>

            while [[ $int_thisExitCode -eq 0 ]]; do
                CheckIfFileIsNull $str_file1
                CreateBackupFromFile $str_file1
                AppendVarToFile $str_file1 $str_output1
                systemctl restart ssh || ( false; SaveThisExitCode )
                break
            done

            # while [[ $int_thisExitCode -eq 0 ]]; do
            #     CheckIfFileIsNull $str_file2
            #     CreateBackupFromFile $str_file2
            #     AppendVarToFile $str_file1 $str_output1
            #     systemctl restart sshd || ( false; SaveThisExitCode )
            #     break
            # done
        fi
    }

    # <summary> Recommended host security changes. </summary>
    # <returns> exit code </returns>
    function ModifySecurity
    {
        echo -e "Configuring system security..."

        # <parameters>
        # str_packagesToRemove="atftpd nis rsh-redone-server rsh-server telnetd tftpd tftpd-hpa xinetd yp-tools"
        declare -lr arr_files1=(
            "/etc/modprobe.d/disable-usb-storage.conf"
            "/etc/modprobe.d/disable-firewire.conf"
            "/etc/modprobe.d/disable-thunderbolt.conf"
        )
        declare -lr str_services="acpupsd cockpit fail2ban ssh ufw"     # include services to enable OR disable: cockpit, ssh, some/all packages installed that are a security-risk or benefit.
        # </parameters>

        # <summary> Set working directory to script root folder. </summary>
        CheckIfDirIsNull $str_filesDir &> /dev/null
        cd $str_filesDir &> /dev/null || ( false; SaveThisExitCode )

        # <summary> Write output to files. </summary>
        if [[ $int_thisExitCode -eq 0 ]]; then
            ReadInput "Disable given device interfaces (for storage devices only): USB, Firewire, Thunderbolt?"

            if [[ $int_thisExitCode -eq 0 ]]; then
                    OverwriteVarToFile /etc/modprobe.d/disable-usb-storage.conf 'install usb-storage /bin/true'
                    OverwriteVarToFile /etc/modprobe.d/disable-firewire.conf "blacklist firewire-core"
                    AppendVarToFile  /etc/modprobe.d/disable-thunderbolt.conf "blacklist thunderbolt"
                    update-initramfs -u -k all
            else
                for var_element1 in ${arr_files1}; do
                    DeleteFile $var_element1 &> /dev/null
                done

                if [[ $int_thisExitCode -eq 0 ]]; then
                    update-initramfs -u -k all
                fi
            fi
        fi

        # <summary> Write output to files. </summary>
        local str_file1="sysctl.conf"
        local str_file2="/etc/sysctl.conf"
        CheckIfFileIsNull $str_file1 &> /dev/null

        while [[ $int_thisExitCode -eq 0 ]]; do
            ReadInput "Setup '/etc/sysctl.conf' with defaults?"
            cp $str_file1 $str_file2 &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            cat $str_file2 >> $str_file1 || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            break
        done

        ReadInput "Setup firewall with UFW?"

        while [[ $int_thisExitCode -eq 0 ]]; do
            # <summary> Default LAN subnets may be 192.168.1.0/24 </summary>
            if [[ $( command -v ufw ) == "" ]]; then
                echo -e "${str_warning}UFW is not installed. Skipping..."
                false; SaveThisExitCode
            fi

            ufw reset &> /dev/null || ( false; SaveThisExitCode )
            ufw default allow outgoing &> /dev/null || ( false; SaveThisExitCode )
            ufw default deny incoming &> /dev/null || ( false; SaveThisExitCode )

            # <summary> SSH on LAN </summary>
            if [[ $( command -v ssh ) != "" ]]; then
                if [[ ${str_sshAlt} != "" ]]; then
                    ufw deny ssh comment 'deny default ssh' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                    ufw limit from 192.168.0.0/16 to any port ${str_sshAlt} proto tcp comment 'ssh' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                else
                    ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
                fi

                ufw deny ssh comment 'deny default ssh' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            fi

            # <summary> Services a desktop may use. </summary>
            ufw allow DNS comment 'dns' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow VNC comment 'VNC, local remote desktop server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )

            # <summary> Services a server may use. </summary>
            # ufw allow http comment 'HTTP, local Web server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            # ufw allow https comment 'HTTPS, local Web server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )

            # ufw allow 25 comment 'SMTPD, local mail server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            # ufw allow 110 comment 'POP3, local mail server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            # ufw allow 995 comment 'POP3S, local mail server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            # ufw allow 1194/udp 'SMTPD, local VPN server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )
            ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server' &> /dev/null || ( SetExitCodeIfPassNorFail; SaveThisExitCode )

            # <summary> Save changes. </summary>
            ufw enable &> /dev/null || ( false; SaveThisExitCode )
            ufw reload &> /dev/null || ( false; SaveThisExitCode )
            break
        done

        # edit hosts file here? #

        EchoPassOrFailThisExitCode "Configuring system security..."; ParseThisExitCode
    }
# </code>

### main functions ###
# <summary> Middleman logic between Program logic and Main code. </summary>
# <code>
    # <summary> Display Help to console. </summary>
    # <returns> exit code </returns>
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
    # <returns> exit code </returns>
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
    # <returns> exit code </returns>
    function ExecuteSystemSetup
    {
        # ModifySecurity
        # ModifySSH
        AppendServices
        # AppendCron
    }

    # <summary> Execute setup of all software repositories. </summary>
    # <returns> exit code </returns>
    function ExecuteSetupOfSoftwareSources
    {
        if [[ $( CheckCurrentDistro ) == true ]]; then
            ModifyDebianRepos

            if [[ $( TestNetwork ) == true ]]; then
                InstallFromDebianRepos
                InstallFromFlathubRepos
                InstallFromSnapRepos
            fi
        fi

        echo -e "\n${str_warning}If system update is/was prematurely stopped, to restart progress, execute in terminal:\n\t'sudo dpkg --configure -a"
    }

    # <summary> Execute setup of GitHub repositories (of which that are executable and installable). </summary>
    # <returns> exit code </returns>
    function ExecuteSetupOfGitRepos
    {
        if [[ $( CheckIfCommandIsInstalled "git" ) == true ]]; then
            if [[ $( TestNetwork ) == true ]]; then
                CloneOrUpdateGitRepositories
            fi

            InstallFromGitRepos
        else
            echo -e "\n${str_warning}Git is not installed on this system."
        fi
    }
# </code>

### global parameters ###
# <summary> Variables to be used throughout the program. </summary>
# <code>
    readonly var_IFS=$IFS
    IFS=$'\n'
    declare -r str_thisDir=$( dirname $0 )
    declare -r str_filesDir=$( dirname $( find .. -name files | uniq | head -n1 ) )
    declare -r str_pwd=$( pwd )
    declare -r str_warning="\e[33mWARNING:\e[0m"" "

    # <summary> Necessary for exit code preservation, for conditional statements. </summary>
    declare -i int_thisExitCode=$?

    # <summary> Checks </summary>
    readonly bool_isUserRoot=$( CheckIfUserIsRoot; ParseThisExitCodeAsBoolean )
    bool_is_xmllint_installed=$( CheckIfCommandIsInstalled "xmllint" )
# </code>

### main ###
# <summary> If you need to a summary to describe this code-block's purpose, you're not gonna make it. </summary>
# <code>
    # <summary> Pre-execution checks. </summary>
    InstallCommands

    # <summary> Execute specific functions if user is sudo/root or not. </summary>
    if [[ $bool_isUserRoot == true ]]; then
        ExecuteSetupOfSoftwareSources
        ExecuteSetupOfGitRepos
        # ExecuteSystemSetup
    else
        ExecuteSetupOfGitRepos
    fi

    # <summary> Post-execution clean up. </summary>
    IFS=$var_IFS
    ExitWithThisExitCode
# </code>