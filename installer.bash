#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

# <summary>
#
# TODO
# - use TestNetwork as a requirement very specifically. Example: if a process can proceed without Internet, allow it to do so.
# - test each business logic method
# - before write, overwrite system file with existing un modified backup.
# - double check usage of exit code partial completion
# - reformat all vars in underscore format
# - debug all functions
# - replace while loops and hard coded num counts with squiggly-bracket ranges (arrays)
#
# RULES
#
# - functions shall be in UpperCamelCase
# - params shall be in lowercase underscore format
# - params tag shall not be nested within a function. It should only be declare once.
# - code should be self-documenting: summary tag is not necessary, but is better for functions and less for code blocks.
# - param tag and returns tag are welcome.
# - create nested subfunctions in business logic with name + "_Main"
#   * such that return statements can be used effectively
#   * and echo statements can pass or fail at any point of a subfunction's end.
# - de-nest as much as possible
# - make package installation distro-agnostic
#   * prioritize debian over other families.
#   * if I can find arch or fedora versions of debian packages, do so. Otherwise, do not execute code.
# - any changes to bash-libraries, upstream back to dev branch.
#
# </summary>

# <summary> #1 - Command operation and validation, and Miscellaneous </summary>
# <code>
    # <summary> Append Pass or Fail given exit code. </summary>
    # <param name="${int_exit_code}"> the last exit code </param>
    # <param name="${1}"> string: the output statement </param>
    # <returns> output statement </returns>
    function AppendPassOrFail
    {
        SaveExitCode
        CheckIfVarIsValid "${1}" &> /dev/null && echo -en "${1} "

        case "${int_exit_code}" in
            0 )
                echo -e "${var_suffix_pass}"
                ;;

            "${int_code_partial_completion}" )
                echo -e "${var_suffix_maybe}"
                ;;

            "${int_code_skipped_operation}" )
                echo -e "${var_suffix_skip}"
                ;;

            * )
                echo -e "${var_suffix_fail}"
                ;;
        esac

        return "${int_exit_code}"
    }

    # <summary> Redirect current directory to shell script root directory. </summary>
    # <param name="${1}"> string: the shell script name </param>
    # <returns> exit code </returns>
    function GoToScriptDir
    {
        cd $( dirname "${0}" ) || return 1
        return 0
    }

    # <summary> Parse and execute from a list of command(s) </summary>
    # <param name="${1}"> array: the list of command(s) </param>
    # <param name="${2}"> array: the list of output statements for each command call </param>
    # <returns> exit code </returns>
    function ParseAndExecuteListOfCommands
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly var_delimiter='|'
        declare -a arr_commands=()
        declare -a arr_commands_output=()
        local readonly str_output_fail="${var_prefix_error} Execution of command failed."
        # </params>

        readarray -t -d ${var_delimiter} <<< ${1} &> /dev/null
        readonly arr_commands=( "${MAPFILE[@]}" )
        CheckIfVarIsValid "${arr_commands[@]}" || return "${?}"

        if CheckIfVarIsValid "${2}" &> /dev/null && readarray -t -d ${var_delimiter} <<< ${2} &> /dev/null; then
            readonly arr_commands_output=( "${MAPFILE[@]}" )
        fi

        for int_key in ${!arr_commands[@]}; do
            local var_command="${arr_commands[$int_key]}"
            local var_command_output="${arr_commands_output[$int_key]}"
            local str_output="Execute '${var_command}'?"

            if CheckIfVarIsValid "${var_command_output}" &> /dev/null; then
                str_output="${var_command_output}"
            fi

            if ReadInput "${str_output}"; then
                ( eval "${var_command}" ) || ( SaveExitCode; echo -e "${str_output_fail}" )
            fi
        done

        return "${int_exit_code}"
    }

    # <summary> Save last exit code. </summary>
    # <param name=""${int_exit_code}""> the exit code </param>
    # <returns> void </returns>
    function SaveExitCode
    {
        int_exit_code="${?}"
    }

    # <summary> Attempt given command a given number of times before failure. </summary>
    # <param name="${1}"> string: the command to execute </param>
    # <returns> exit code </returns>
    function TryThisXTimesBeforeFail
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        local readonly str_output_fail="${var_prefix_error} Execution of command failed."
        # </params>

        for int_count in ${arr_count[@]}; do
            eval "${1}" && return 0 || echo -e "${str_output_fail}"
        done

        return 1
    }
# </code>

# <summary> #2 - Data-type and variable validation </summary>
# <code>
    # <summary> Check if the command is installed. </summary>
    # <param name="${1}"> string: the command </param>
    # <returns> exit code </returns>
    #
    function CheckIfCommandIsInstalled
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Command '${1}' is not installed."
        local readonly var_actual_install_path=$( command -v "${1}" )
        local readonly var_expected_install_path="/usr/bin/${1}"
        # </params>

        # if $( ! CheckIfFileExists $var_actual_install_path ) &> /dev/null || [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
        # if ! CheckIfFileExists $var_actual_install_path &> /dev/null; then

        if [[ "${var_actual_install_path}" != "${var_expected_install_path}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_cmd_is_null}"
        fi

        return 0
    }

    # <summary> Check if the value is a valid bool. </summary>
    # <param name="${1}"> var: the boolean </param>
    # <returns> exit code </returns>
    #
    function CheckIfVarIsBool
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Not a boolean."
        # </params>

        case "${1}" in
            "true" | "false" )
                return 0
                ;;

            * )
                echo -e "${str_output_fail}"
                return "${int_code_var_is_not_bool}"
                ;;
        esac
    }

    # <summary> Check if the value is a valid number. </summary>
    # <param name="${1}"> var: the number </param>
    # <returns> exit code </returns>
    #
    function CheckIfVarIsNum
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_num_regex='^[0-9]+$'
        local readonly str_output_fail="${var_prefix_error} NaN."
        # </params>

        if ! [[ "${1}" =~ $str_num_regex ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_var_is_NAN}"
        fi

        return 0
    }

    # <summary> Check if the value is valid. </summary>
    # <param name="${1}"> string: the variable </param>
    # <returns> exit code </returns>
    #
    function CheckIfVarIsValid
    {
        # <params>
        local readonly str_output_var_is_null="${var_prefix_error} Null string."
        local readonly str_output_var_is_empty="${var_prefix_error} Empty string."
        # </params>

        if [[ -z "${1}" ]]; then
            echo -e "${str_output_var_is_null}"
            return "${int_code_var_is_null}"
        fi

        if [[ "${1}" == "" ]]; then
            echo -e "${str_output_var_is_empty}"
            return "${int_code_var_is_empty}"
        fi

        return 0
    }

    # <summary> Check if the directory exists. </summary>
    # <param name="${1}"> string: the directory </param>
    # <returns> exit code </returns>
    #
    function CheckIfDirExists
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} Directory '${1}' does not exist."
        # </params>

        if [[ ! -d "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_dir_is_null}"
        fi

        return 0
    }

    # <summary> Check if the file exists. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    #
    function CheckIfFileExists
    {
        CheckIfVarIsValid "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' does not exist."
        # </params>

        if [[ ! -e "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_null}"
        fi

        return 0
    }

    # <summary> Check if the file is executable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    #
    function CheckIfFileIsExecutable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not executable."
        # </params>

        if [[ ! -x "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_not_executable}"
        fi

        return 0
    }

    # <summary> Check if the file is readable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    #
    function CheckIfFileIsReadable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not readable."
        # </params>

        if [[ ! -r "${1}" ]]; then
            echo -e "${str_output_fail}"
            return "${int_code_file_is_not_readable}"
        fi

        return 0
    }

    # <summary> Check if the file is writable. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    #
    function CheckIfFileIsWritable
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_error} File '${1}' is not writable."
        # </params>

        if [[ ! -w "${1}" ]]; then
            echo -e "${str_output_fail}"
            return $int_code_file_is_not_writable
        fi

        return 0
    }

    # <summary> Parse exit code as boolean. If non-zero, return false. </summary>
    # <param name="${?}"> int: the exit code </param>
    # <returns> boolean </returns>
    function ParseExitCodeAsBool
    {
        if [[ "${?}" -ne 0 ]]; then
            echo false
            return 1
        fi

        echo true
        return 0
    }
# </code>

# <summary> #3 - User validation </summary>
# <code>
    # <summary> Check if current user is sudo or root. </summary>
    # <returns> exit code </returns>
    function CheckIfUserIsRoot
    {
        # <params>
        local readonly str_file=$( basename "${0}" )
        local readonly str_output_user_is_not_root="${var_prefix_warn} User is not Sudo/Root. In terminal, enter: ${var_yellow}'sudo bash ${str_file}' ${var_reset_color}"
        # </params>

        if [[ $( whoami ) != "root" ]]; then
            echo -e "${str_output}"_user_is_not_root
            return 1
        fi

        return 0
    }
# </code>

# <summary> #4 - File operation and validation </summary>
# <code>
    # <summary> Check if two given files are the same. </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <parameter name="${2}"> string: the file </parameter>
    # <returns> exit code </returns>
    function CheckIfTwoFilesAreSame
    {
        ( CheckIfFileExists "${1}" && CheckIfFileExists "${2}" ) || return "${?}"
        cmp -s "${1}" "${2}" || return 1
        return 0
    }

    # <summary> Create latest backup of given file (do not exceed given maximum count). </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <returns> exit code </returns>
    function CreateBackupFile
    {
        function CreateBackupFile_Main
        {
            CheckIfFileExists "${1}" || return "${?}"

            # <params>
            declare -ir int_max_count=4
            local readonly str_dir1=$( dirname "${1}" )
            local readonly str_suffix=".old"
            var_get_dir1='ls "${str_dir1}" | grep "${1}" | grep $str_suffix | uniq | sort -V'
            declare -a arr_dir1=( $( eval "$var_get_dir1" ) )
            # </params>

            # <summary> Create backup file if none exist. </summary>
            if [[ "${#arr_dir1[@]}" -eq 0 ]]; then
                cp "${1}" "${1}.${var_first_index}${str_suffix}" || return 1
                return 0
            fi

            # <summary> Oldest backup file is same as original file. </summary>
            CheckIfTwoFilesAreSame "${1}" "${arr_dir1[0]}" && return 0

            # <summary> Get index of oldest backup file. </summary>
            local str_oldest_file="${arr_dir1[0]}"
            str_oldest_file="${str_oldest_file%%"${str_suffix}"*}"
            local var_first_index="${str_oldest_file##*.}"
            CheckIfVarIsNum "$var_first_index" || return "${?}"

            # <summary> Delete older backup files, if total matches/exceeds maximum. </summary>
            while [[ "${#arr_dir1[@]}" -gt "$int_max_count" ]]; do
                DeleteFile "${arr_dir1[0]}" || return "${?}"
                arr_dir1=( $( eval "$var_get_dir1" ) )
            done

            # <summary> Increment number of last backup file index. </summary>
            local str_newest_file="${arr_dir1[-1]}"
            str_newest_file="${str_newest_file%%"${str_suffix}"*}"
            local var_last_index="${str_newest_file##*.}"
            CheckIfVarIsNum "${var_last_index}" || return "${?}"
            (( var_last_index++ ))

            # <summary> Newest backup file is different and newer than original file. </summary>
            if ( ! CheckIfTwoFilesAreSame "${1}" "${arr_dir1[-1]}" &> /dev/null ) && [[ "${1}" -nt "${arr_dir1[-1]}" ]]; then
                cp "${1}" "${1}.${var_last_index}${str_suffix}" || return 1
            fi

            return 0
        }

        # <params>
        local readonly str_output="Creating backup file..."
        # </params>

        echo -e "${str_output}"
        CreateBackupFile_Main "${1}"
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Create a directory. </summary>
    # <param name="${1}"> string: the directory </param>
    # <returns> exit code </returns>
    function CreateDir
    {
        CheckIfDirExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create directory '${1}'."
        # </params>

        mkdir -p "${1}" || (
            echo -e "${str_output_fail}"
            return 1
        )

        return 0
    }

    # <summary> Create a file. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function CreateFile
    {
        CheckIfFileExists "${1}" &> /dev/null && return 0

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not create file '${1}'."
        # </params>

        touch "${1}" || (
            echo -e "${str_output_fail}"
            return 1
        )

        return 0
    }

    # <summary> Delete a dir/file. </summary>
    # <param name="${1}"> string: the file </param>
    # <returns> exit code </returns>
    function DeleteFile
    {
        CheckIfFileExists "${1}" || return 0

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not delete file '${1}'."
        # </params>

        rm "${1}" || (
            echo -e "${str_output_fail}"
            return 1
        )

        return 0
    }

    # <summary> Read input from a file. Call '$var_file' after calling this function. </summary>
    # <param name="${1}"> string: the file </param>
    # <param name="${2}"> array: the file contents </param>
    # <returns> exit code </returns>
    function ReadFromFile
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        local readonly str_output_fail="${var_prefix_fail} Could not read from file '${1}'."
        local readonly var_command='cat "${1}"'
        # </params>

        eval "${var_command}" || return 1
        return 0
    }

    # <summary> Restore latest valid backup of given file. </summary>
    # <parameter name="${1}"> string: the file </parameter>
    # <returns> exit code </returns>
    function RestoreBackupFile
    {
        function RestoreBackupFile_Main
        {
            CheckIfFileExists "${1}" || return "${?}"

            # <params>
            local readonly str_dir1=$( dirname "${1}" )
            local readonly str_suffix=".old"
            var_get_dir1='ls "${str_dir1}" | grep "${1}" | grep $str_suffix | uniq | sort -rV'
            declare -a arr_dir1=( $( eval "$var_get_dir1" ) )
            # </params>

            CheckIfVarIsValid ${arr_dir1[@]} || return "${?}"

            for var_element1 in ${arr_dir1[@]}; do
                CheckIfFileExists "${var_element1}" && cp "${var_element1}" "${1}" && return 0
            done

            return 1
        }

        # <params>
        local readonly str_output="Restoring backup file..."
        # </params>

        echo -e "${str_output}"
        RestoreBackupFile_Main "${1}"
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Write output to a file. Call '$var_file' after calling this function. </summary>
    # <param name="${1}"> string: the file </param>
    # <param name="${2}"> array: the file contents </param>
    # <returns> exit code </returns>
    function WriteToFile
    {
        CheckIfFileExists "${1}" || return "${?}"

        # <params>
        IFS=$'\n'
        declare -a arr_file=()
        local readonly str_output_fail="${var_prefix_fail} Could not write to file '${1}'."
        local readonly var_delimiter='|'
        # </params>

        if readarray -t -d ${var_delimiter} <<< ${1} &> /dev/null; then
            readonly arr_file=( "${MAPFILE[@]}" )
        fi

        CheckIfVarIsValid "${arr_file[@]}" || return "${?}"

        # ( printf "%s\n" "${arr_file[@]}" >> "${1}" ) || (
        #     echo -e "${str_output_fail}"
        #     return 1
        # )

        for var_element in ${arr_file[@]}; do
            echo -e "${var_element}" >> "${1}" || (
                echo -e "${str_output_fail}"
                return 1
            )
        done

        return 0
    }
# </code>

# <summary> #5 - Device validation </summary>
# <code>
    # <summary> Check if current kernel and distro are supported, and if the expected Package Manager is installed. </summary>
    # <returns> exit code </returns>
    function CheckLinuxDistro
    {
        # <params>
        local readonly str_kernel="$( uname -o | tr '[:upper:]' '[:lower:]' )"
        local readonly str_operating_system="$( lsb_release -is | tr '[:upper:]' '[:lower:]' )"
        local readonly str_output_distro_is_not_valid="${var_prefix_error} Distribution '$( lsb_release -is )' is not supported."
        local readonly str_output_kernel_is_not_valid="${var_prefix_error} Kernel '$( uname -o )' is not supported."
        local readonly str_OS_with_apt="debian bodhi deepin knoppix mint peppermint pop ubuntu kubuntu lubuntu xubuntu "
        local readonly str_OS_with_dnf_yum="redhat berry centos cern clearos elastix fedora fermi frameos mageia opensuse oracle scientific suse"
        local readonly str_OS_with_pacman="arch manjaro"
        local readonly str_OS_with_portage="gentoo"
        local readonly str_OS_with_urpmi="opensuse"
        local readonly str_OS_with_zypper="mandriva mageia"
        # </params>

        ( CheckIfVarIsValid "${str_kernel}" &> /dev/null && CheckIfVarIsValid "${str_operating_system}" &> /dev/null ) || return "${?}"

        if [[ "${str_kernel}" != *"linux"* ]]; then
            echo -e "${str_output_kernel_is_not_valid}"
            return 1
        fi

        # <summary> Check if current Operating System matches Package Manager, and Check if PM is installed. </summary>
        # <returns> exit code </returns>
        function CheckLinuxDistro_GetPackageManagerByOS
        {
            if [[ "${str_OS_with_apt}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="apt"

            elif [[ "${str_OS_with_dnf_yum}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="dnf"
                CheckIfCommandIsInstalled "${str_package_manager}" &> /dev/null && return 0
                str_package_manager="yum"

            elif [[ "${str_OS_with_pacman}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="pacman"

            elif [[ "${str_OS_with_portage}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="portage"

            elif [[ "${str_OS_with_urpmi}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="urpmi"

            elif [[ "${str_OS_with_zypper}" =~ .*"${str_operating_system}".* ]]; then
                str_package_manager="zypper"

            else
                str_package_manager=""
                return 1
            fi

            CheckIfCommandIsInstalled "${str_package_manager}" &> /dev/null && return 0
            return 1
        }

        if ! CheckLinuxDistro_GetPackageManagerByOS; then
            echo -e "${str_output_distro_is_not_valid}"
            return 1
        fi

        return 0
    }

    # <summary> Test network connection to Internet. Ping DNS servers by address and name. </summary>
    # <param name="${1}"> boolean: true/false set/unset verbosity </param>
    # <returns> exit code </returns>
    function TestNetwork
    {
        # <params>
        local bool=false
        # </params>

        if CheckIfVarIsBool "${1}" &> /dev/null && "${1}"; then
            local bool="${1}"
        fi

        if $bool; then
            echo -en "Testing Internet connection...\t"
        fi

        ( ping -q -c 1 8.8.8.8 || ping -q -c 1 1.1.1.1 ) &> /dev/null || false

        SaveExitCode

        if $bool; then
            ( return "${int_exit_code}" )
            AppendPassOrFail
            echo -en "Testing connection to DNS...\t"
        fi

        ( ping -q -c 1 www.google.com && ping -q -c 1 www.yandex.com ) &> /dev/null || false

        SaveExitCode

        if $bool; then
            ( return "${int_exit_code}" )
            AppendPassOrFail
        fi

        if [[ "${int_exit_code}" -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        return "${int_exit_code}"
    }
# </code>

# <summary> #6 - User input </summary>
# <code>
    # <summary> Ask user Yes/No, read input and return exit code given answer. </summary>
    # <param name="${1}"> string: the output statement </param>
    # <returns> exit code </returns>
    #
    function ReadInput
    {
        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        local str_output=""
        # </params>

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        declare -r str_output+="${var_green}[Y/n]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do

            # <summary> Append output. </summary>
            echo -en "${str_output} "
            read var_input
            var_input=$( echo $var_input | tr '[:lower:]' '[:upper:]' )

            # <summary> Check if input is valid. </summary>
            if CheckIfVarIsValid $var_input; then
                case $var_input in
                    "Y")
                        return 0;;
                    "N")
                        return 1;;
                esac
            fi

            # <summary> Input is not valid. </summary>
            echo -e "${str_output_var_is_not_valid}"
        done

        # <summary> After given number of attempts, input is set to default. </summary>
        echo -e "${var_prefix_warn} Exceeded max attempts. Choice is set to default: N"
        return 1
    }

    # <summary>
    # Ask for a number, within a given range, and return given number.
    # If input is not valid, return minimum value. Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <parameter name="${2}"> num: absolute minimum </parameter>
    # <parameter name="${3}"> num: absolute maximum </parameter>
    # <parameter name="$var_input"> the answer </parameter>
    # <returns> $var_input </returns>
    function ReadInputFromRangeOfTwoNums
    {
        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        local readonly var_min=${2}
        local readonly var_max=${3}
        local str_output=""
        local readonly str_output_extrema_are_not_valid="${var_prefix_error} Extrema are not valid."
        var_input=""
        # </params>

        if ( ! CheckIfVarIsNum $var_min || ! CheckIfVarIsNum $var_max ) &> /dev/null; then
            echo -e "${str_output}"_extrema_are_not_valid
            return 1
        fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "

        readonly str_output+="${var_green}[${var_min}-${var_max}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do

            # <summary> Append output. </summary>
            echo -en "${str_output} "
            read var_input

            # <summary> Check if input is valid. </summary>
            if CheckIfVarIsNum $var_input && [[ $var_input -ge $var_min && $var_input -le $var_max ]]; then
                return 0
            fi

            # <summary> Input is not valid. </summary>
            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=$var_min
        echo -e "Exceeded max attempts. Choice is set to default: ${var_input}"
        return 1
    }

    # <summary>
    # Ask user for multiple choice, and return choice given answer.
    # If input is not valid, return first value. Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <param name="${2}" name="${3}" name="${4}" name="${5}" name="${6}" name="${7}" name="${8}"> multiple choice </param>
    # <param name="$var_input"> the answer </param>
    # <returns> the answer </returns>
    #
    function ReadMultipleChoiceIgnoreCase
    {
        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            SaveExitCode
            echo -e "${str_output}"_multiple_choice_not_valid
            return "${int_exit_code}"
        fi

        arr_input+=( "${2}" )
        arr_input+=( "${3}" )

        if CheckIfVarIsValid "${4}" &> /dev/null; then arr_input+=( "${4}" ); fi
        if CheckIfVarIsValid "${5}" &> /dev/null; then arr_input+=( "${5}" ); fi
        if CheckIfVarIsValid "${6}" &> /dev/null; then arr_input+=( "${6}" ); fi
        if CheckIfVarIsValid "${7}" &> /dev/null; then arr_input+=( "${7}" ); fi
        if CheckIfVarIsValid "${8}" &> /dev/null; then arr_input+=( "${8}" ); fi
        if CheckIfVarIsValid "${9}" &> /dev/null; then arr_input+=( "${9}" ); fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        readonly str_output+="${var_green}[${arr_input[@]}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do
            echo -en "${str_output} "
            read var_input

            if CheckIfVarIsValid $var_input; then
                var_input=$( echo $var_input | tr '[:lower:]' '[:upper:]' )

                for var_element in ${arr_input[@]}; do
                    if [[ "${var_input}" == $( echo $var_element | tr '[:lower:]' '[:upper:]' ) ]]; then
                        var_input=$var_element
                        return 0
                    fi
                done
            fi

            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=${arr_input[0]}
        echo -e "Exceeded max attempts. Choice is set to default: ${var_input}"
        return 1
    }

    # <summary>
    # Ask user for multiple choice, and return given choice.
    # If input is not valid, return first value.
    # Declare '$var_input' before calling this function.
    # </summary>
    # <parameter name="${1}"> string: the output statement </parameter>
    # <param name="${2}" name="${3}" name="${4}" name="${5}" name="${6}" name="${7}" name="${8}"> multiple choice </param>
    # <param name="$var_input"> the answer </param>
    # <returns> the answer </returns>
    #
    function ReadMultipleChoiceMatchCase
    {
        # <params>
        declare -ir int_min_count=1
        declare -ir int_max_count=3
        declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
        declare -a arr_input=()
        local str_output=""
        local readonly str_output_multiple_choice_not_valid="${var_prefix_error} Insufficient multiple choice answers."
        var_input=""
        # </params>

        # <summary> Minimum multiple choice are two answers. </summary>
        if ( ! CheckIfVarIsValid "${2}" || ! CheckIfVarIsValid "${3}" ) &> /dev/null; then
            echo -e "${str_output}"_multiple_choice_not_valid
            return 1;
        fi

        arr_input+=( "${2}" )
        arr_input+=( "${3}" )

        if CheckIfVarIsValid "${4}" &> /dev/null; then arr_input+=( "${4}" ); fi
        if CheckIfVarIsValid "${5}" &> /dev/null; then arr_input+=( "${5}" ); fi
        if CheckIfVarIsValid "${6}" &> /dev/null; then arr_input+=( "${6}" ); fi
        if CheckIfVarIsValid "${7}" &> /dev/null; then arr_input+=( "${7}" ); fi
        if CheckIfVarIsValid "${8}" &> /dev/null; then arr_input+=( "${8}" ); fi
        if CheckIfVarIsValid "${9}" &> /dev/null; then arr_input+=( "${9}" ); fi

        CheckIfVarIsValid "${1}" &> /dev/null && str_output="${1} "
        readonly str_output+="${var_green}[${arr_input[@]}]:${var_reset_color}"

        for int_count in ${arr_count[@]}; do
            echo -en "${str_output} "
            read var_input

            if CheckIfVarIsValid $var_input &> /dev/null; then
                for var_element in ${arr_input[@]}; do
                    if [[ "${var_input}" == "${var_element}" ]]; then
                        var_input=$var_element
                        return 0
                    fi
                done
            fi

            echo -e "${str_output_var_is_not_valid}"
        done

        var_input=${arr_input[0]}
        echo -e "Exceeded max attempts. Choice is set to default: ${var_input}"
        return 1
    }
# </code>

# <summary> #7 - Software installation </summary>
# <code>
    # <summary> Distro-agnostic, Check if package exists on-line. </summary>
    # <param name="${1}"> string: the software package(s) </param>
    # <returns> exit code </returns>
    function CheckIfPackageExists
    {
        ( CheckIfVarIsValid "${1}" && CheckIfVarIsValid "${str_package_manager}" )|| return "${?}"

        # <params>
        local str_commands_to_execute=""
        local readonly str_output="${var_prefix_fail}: Command '${str_package_manager}' is not supported."
        # </params>

        case "${str_package_manager}" in
            "apt" )
                str_commands_to_execute="apt list ${1}"
                ;;

            "dnf" )
                str_commands_to_execute="dnf search ${1}"
                ;;

            "pacman" )
                str_commands_to_execute="pacman -Ss ${1}"
                ;;

            "gentoo" )
                str_commands_to_execute="emerge --search ${1}"
                ;;

            "urpmi" )
                str_commands_to_execute="urpmq ${1}"
                ;;

            "yum" )
                str_commands_to_execute="yum search ${1}"
                ;;

            "zypper" )
                str_commands_to_execute="zypper se ${1}"
                ;;

            * )
                echo -e "${str_output}"
                return 1
                ;;
        esac

        eval "${str_command}"s_to_execute || return 1
    }

    # <summary> Distro-agnostic, Install a software package. </summary>
    # <param name="${1}"> string: the software package(s) </param>
    # <param name="${2}"> boolean: true/false do/don't reinstall software package and configuration files (if possible) </param>
    # <returns> exit code </returns>
    function InstallPackage
    {
        ( CheckIfVarIsValid "${1}" && CheckIfVarIsValid "${str_package_manager}" )|| return "${?}"

        # <params>
        ( CheckIfVarIsBool "${2}" &> /dev/null && local bool_option_reinstall=${2} )
        local str_commands_to_execute=""
        local readonly str_output="Installing software packages..."
        local readonly str_output_fail="${var_prefix_fail}: Command '${str_package_manager}' is not supported."
        # </params>

        # <summary> Auto-update and auto-install selected packages </summary>
        case "${str_package_manager}" in
            "apt" )
                str_option1="--reinstall -o Dpkg::Options::=--force-confmiss"
                str_commands_to_execute="apt update && apt full-upgrade -y && apt install ${str_option1} -y ${1}"
                ;;

            "dnf" )
                str_commands_to_execute="dnf upgrade && dnf install ${1}"
                ;;

            "pacman" )
                str_commands_to_execute="pacman -Syu && pacman -S ${1}"
                ;;

            "gentoo" )
                str_commands_to_execute="emerge -u @world && emerge www-client/${1}"
                ;;

            "urpmi" )
                str_commands_to_execute="urpmi --auto-update && urpmi ${1}"
                ;;

            "yum" )
                str_commands_to_execute="yum update && yum install ${1}"
                ;;

            "zypper" )
                str_commands_to_execute="zypper refresh && zypper in ${1}"
                ;;

            * )
                echo -e "${str_output_fail}"
                return 1
                ;;
        esac

        echo "${str_output}"
        eval "${str_commands_to_execute}" &> /dev/null || ( return 1 )
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Update or Clone repository given if it exists or not. </summary>
    # <param name="${1}"> string: the directory </param>
    # <param name="${2}"> string: the full repo name </param>
    # <param name="${3}"> string: the username </param>
    # <returns> exit code </returns>
    function UpdateOrCloneGitRepo
    {
        # <summary> Update existing GitHub repository. </summary>
        if CheckIfDirExists "${1}${2}"; then
            cd "${1}${2}" && TryThisXTimesBeforeFail "git pull"
            return "${?}"

        # <summary> Clone new GitHub repository. </summary>
        else
            if ReadInput "Clone repo '${2}'?"; then
                cd "${1}${3}" && TryThisXTimesBeforeFail "git clone https://github.com/${2}"
                return "${?}"
            fi
        fi
    }
# </code>

# <summary> Global parameters </summary>
# <params>
    # <summary> Getters and Setters </summary>
        declare -g bool_is_installed_systemd=false
        CheckIfCommandIsInstalled "systemd" &> /dev/null && bool_is_installed_systemd=true

        declare -g bool_is_user_root=false
        CheckIfUserIsRoot &> /dev/null && bool_is_user_root=true

        declare -gl str_package_manager=""
        CheckLinuxDistro &> /dev/null

    # <summary> Setters </summary>
        # <summary> Exit codes </summary>
        declare -gir int_code_partial_completion=255
        declare -gir int_code_skipped_operation=254
        declare -gir int_code_var_is_null=253
        declare -gir int_code_var_is_empty=252
        declare -gir int_code_var_is_not_bool=251
        declare -gir int_code_var_is_NAN=250
        declare -gir int_code_dir_is_null=249
        declare -gir int_code_file_is_null=248
        declare -gir int_code_file_is_not_executable=247
        declare -gir int_code_file_is_not_writable=246
        declare -gir int_code_file_is_not_readable=245
        declare -gir int_code_cmd_is_null=244
        declare -gi int_exit_code="${?}"

        # <summary>
        # Color coding
        # Reference URL: 'https://www.shellhacks.com/bash-colors'
        # </summary>
        declare -gr var_blinking_red='\033[0;31;5m'
        declare -gr var_green='\033[0;32m'
        declare -gr var_red='\033[0;31m'
        declare -gr var_yellow='\033[0;33m'
        declare -gr var_reset_color='\033[0m'

        # <summary> Append output </summary>
        declare -gr var_prefix_error="${var_yellow}Error:${var_reset_color}"
        declare -gr var_prefix_fail="${var_red}Failure:${var_reset_color}"
        declare -gr var_prefix_pass="${var_green}Success:${var_reset_color}"
        declare -gr var_prefix_warn="${var_blinking_red}Warning:${var_reset_color}"
        declare -gr var_suffix_fail="${var_red}Failure${var_reset_color}"
        declare -gr var_suffix_maybe="${var_yellow}Successfully Incomplete${var_reset_color}"
        declare -gr var_suffix_pass="${var_green}Success${var_reset_color}"
        declare -gr var_suffix_skip="${var_yellow}Skipped${var_reset_color}"

        # <summary> Output statement </summary>
        declare -gr str_output_partial_completion="${var_prefix_warn} One or more operations failed."
        declare -gr str_output_var_is_not_valid="${var_prefix_error} Invalid input."
# </params>

# <summary> Program business logic </summary>
# <code>
    # <summary> Crontab </summary>
    # <returns> exit code </returns>
    function AppendCron
    {
        # <summary> Match given cron file, append only if package exists in system. </summary>
        # <param name="${str_dir}"> str: the directory </param>
        # <param name="${str_file}"> str: the cron file </param>
        # <param name="${bool_nonzero_amount_of_failed_operations}"> bool: flag for failed operation </param>
        # <returns> flag for failed operation </returns>
        function AppendCron_MatchCronFile
        {
            for str_actual_package in ${arr_actual_packages[@]}; do
                if [[ "${str_file}" == *"${str_actual_package}"* ]]; then
                    if CheckIfCommandIsInstalled "${str_actual_package}"; then
                        cp "${str_file}" "${str_dir}${str_file}" || bool_nonzero_amount_of_failed_operations=true
                    else
                        bool_nonzero_amount_of_failed_operations=true
                    fi
                fi
            done
        }

        function AppendCron_Main
        {
            # <params>
            local bool_nonzero_amount_of_failed_operations=false
            declare -a arr_actual_packages=()
            local readonly str_dir="/etc/cron.d/"
            # </params>

            for str_expected_package in ${arr_expected_packages[@]}; do
                if ! CheckIfCommandIsInstalled "${str_expected_package}" &> /dev/null; then
                    InstallPackage "${str_expected_package}"
                fi

                if CheckIfCommandIsInstalled "${str_expected_package}" &> /dev/null; then
                    arr_actual_packages+=( "${str_expected_package}" )
                fi
            done

            CheckIfVarIsValid "${str_package_manager}" && (
                case "${str_package_manager}" in
                    "apt" )
                        local str_alternate_package="unattended-upgrades"
                        CheckIfCommandIsInstalled "${str_alternate_package}" &> /dev/null || arr_actual_packages+=( "${str_package_manager}" )
                        ;;

                    * )
                        arr_actual_packages+=( "${str_package_manager}" )
                        ;;
                esac
            )

            cd $( dirname "${0}" )
            CheckIfDirExists "${str_files_dir}" || return "${?}"
            cd "${str_files_dir}" || return 1
            local readonly var_command='ls *-cron'

            for str_file in eval "${var_command}"; do
                local str_output="Append '${str_file}'?"
                ReadInput "${str_output}" && AppendCron_MatchCronFile
            done

            local readonly var_service="cron"
            systemctl enable "${var_service}" || return 1
            systemctl restart "${var_service}" || return 1

            $bool_nonzero_amount_of_failed_operations &> /dev/null && return "${int_code_partial_completion}"
            return 0
        }

        # <params>
        local readonly str_output="Appending cron entries..."
        # </params>

        echo -e "${str_output}"
        AppendCron_Main
        AppendPassOrFail "${str_output}"

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }

    # <summary> Append SystemD services to host. </summary>
    # <returns> exit code </returns>
    function AppendServices
    {
        # <summary> Copy files and set permissions. </summary>
        # <param name="${1}"> string: the new file </param>
        # <param name="${2}"> string: the system file </param>
        # <returns> exit code </returns>
        function AppendServices_AppendFile
        {
            if CheckIfFileExists "${2}" &> /dev/null; then
                cp "${1}" "${2}" || return 1
                chown root "${2}" || return 1
                chmod +x "${2}" || return 1
                CheckIfDirExists "${str_files_dir}" || return "${?}"
                cd "${str_files_dir}"
            fi

            return 0
        }

        function AppendServices_Main
        {
            # <params>
            local readonly str_pattern=".service"
            declare -ar arr_dir1=( $( ls | uniq | grep -Ev ${str_pattern} ) )
            declare -ar arr_dir2=( $( ls | uniq | grep ${str_pattern} ))
            local readonly var_command_update_services='systemctl daemon-reload'
            # </params>

            # <summary> Copy binaries to system. </summary>
            for str_binary in ${arr_dir1[@]}; do
                local str_file="/usr/sbin/${str_binary}"
                AppendServices_AppendFile "${str_binary}" "${str_file}"
            done

            # <summary> Copy services to system. </summary>
            for str_service in ${arr_dir2[@]}; do
                local str_file="/etc/systemd/system/${str_service}"
                AppendServices_AppendFile "${str_service}" "${str_file}"

                if AppendServices_AppendFile "${str_service}" "${str_file}"; then
                    eval "${var_command_update_services}"

                    local str_output="Enable/disable '${str_service}'?"

                    if ReadInput "${str_output}"; then
                        systemctl enable "${str_service}"
                    else
                        systemctl disable "${str_service}"
                    fi
                fi
            done

            eval "${var_command_update_services}" || return 1
        }

        # <params>
        local readonly str_output="Appending files to Systemd..."
        # </params>

        echo -e "${str_output}"
        AppendServices_Main
        AppendPassOrFail "${str_output}"

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }

    # <summary> Clone given GitHub repositories. </summary>
    # <returns> exit code </returns>
    function CloneOrUpdateGitRepositories
    {
        # NOTE: Update Here!
        # <summary> Get params. </summary>
        # <returns> params </returns>
        function CloneOrUpdateGitRepositories_GetParams
        {
            # <summary> Example: "username/reponame" </summary>
            if $bool_is_user_root; then
                local readonly str_dir="/root/source/"

                declare -ar arr_repo=(
                    "corna/me_cleaner"
                    "dt-zero/me_cleaner"
                    "foundObjects/zram-swap"
                    "portellam/Auto-Xorg"
                    "portellam/deploy-VFIO-setup"
                    "pyllyukko/user.js"
                    "StevenBlack/hosts"
                )
            else
                local readonly str_dir=$( echo ~/ )"source/"

                declare -ar arr_repo=(
                    "awilliam/rom-parser"
                    #"pixelplanetdev/4chan-flag-filter"
                    #"pyllyukko/user.js"
                    "SpaceinvaderOne/Dump_GPU_vBIOS"
                    "spheenik/vfio-isolate"
                )
            fi

            echo
        }

        function CloneOrUpdateGitRepositories_Main
        {
            # <params>
            local bool_nonzero_amount_of_failed_repos=false
            local str_dir=""
            declare -a arr_repos=()
            CloneOrUpdateGitRepositories_GetParams
            # </params>

            CreateDir "${str_dir}" || return "${?}"
            chmod -R +w "${str_dir}" || return 1

            # <summary> Should code execution fail at any point, skip to next repo. </summary>
            for str_repo in ${arr_repos[@]}; do
                if cd "${str_dir}"; then
                    local str_user_name=$( echo "${str_repo}" | cut -d "/" -f1 )
                    if ! CheckIfDirExists "${str_dir}${str_user_name}"; then
                        CreateDir "${str_dir}${str_user_name}"
                    fi

                    if CheckIfDirExists "${str_dir}${str_user_name}" && ! UpdateOrCloneGitRepo "${str_dir}" "${str_repo}" "${str_user_name}"; then
                        bool_nonzero_amount_of_failed_repos=true
                        echo
                    fi
                fi
            done

            $bool_nonzero_amount_of_failed_operations &> /dev/null && return "${int_code_partial_completion}"
            return 0
        }

        # <params>
        local readonly str_output="Cloning Git repos..."
        local readonly str_output_partial_completion="${var_prefix_warn} One or more Git repositories were not cloned."
        # </params>

        echo -e "${str_output}"
        CloneOrUpdateGitRepositories_Main
        AppendPassOrFail "${str_output}"

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }

    # <summary> Install from this Linux distribution's repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromLinuxRepos
    {
        # NOTE: Update Here!
        # <summary> Get params. </summary>
        # <returns> params </returns>
        function InstallFromLinuxRepos_GetParamsForAPT
        {
            # <params>
            declare -a arr_packages_to_install=()

            declare -ar arr_packages_Required=(
                "systemd-timesyncd"
            )

            declare -ar arr_packages_Commands=(
                "curl"
                "flashrom"
                "lm-sensors"
                "neofetch"
                "unzip"
                "wget"
                "youtube-dl"
            )

            declare -ar arr_packages_Compatibilty=(
                "java-common"
                "python3"
                "qemu"
                "virt-manager"
                "wine"
            )

            declare -ar arr_packages_Developer=(
                ""
            )

            declare -ar arr_packages_Drivers=(
                "apcupsd"
                "rtl-sdr"
                "steam-devices"
            )

            declare -ar arr_packages_Games=(
                ""
            )

            declare -ar arr_packages_Internet=(
                "firefox-esr"
                "filezilla"
            )

            declare -ar arr_packages_Media=(
                "vlc"
            )

            declare -ar arr_packages_Office=(
                "libreoffice"
            )

            declare -ar arr_packages_PrismBreak=(
                ""
            )

            declare -ar arr_packages_Repos=(
                "git"
                "flatpak"
                "snap"
            )

            declare -ar arr_packages_Security=(
                "apt-listchanges"
                "bsd-mailx"
                "fail2ban"
                "gufw"
                "ssh"
                "ufw"
                "unattended-upgrades"
            )

            declare -ar arr_packages_Suites=(
                "debian-edu-install"
                "science-all"
            )

            declare -ar arr_packages_Tools=(
                "bleachbit"
                "cockpit"
                "grub-customizer"
                "synaptic"
                "zram-tools"
            )

            declare -ar arr_packages_VGA_drivers=(
                "nvidia-detect"
                "xserver-xorg-video-all"
                "xserver-xorg-video-amdgpu"
                "xserver-xorg-video-ati"
                "xserver-xorg-video-cirrus"
                "xserver-xorg-video-fbdev"
                "xserver-xorg-video-glide"
                "xserver-xorg-video-intel"
                "xserver-xorg-video-ivtv-dbg"
                "xserver-xorg-video-ivtv"
                "xserver-xorg-video-mach64"
                "xserver-xorg-video-mga"
                "xserver-xorg-video-neomagic"
                "xserver-xorg-video-nouveau"
                "xserver-xorg-video-openchrome"
                "xserver-xorg-video-qxl/"
                "xserver-xorg-video-r128"
                "xserver-xorg-video-radeon"
                "xserver-xorg-video-savage"
                "xserver-xorg-video-siliconmotion"
                "xserver-xorg-video-sisusb"
                "xserver-xorg-video-tdfx"
                "xserver-xorg-video-trident"
                "xserver-xorg-video-vesa"
                "xserver-xorg-video-vmware"
            )

            declare -ar arr_packages_Unsorted=(
                ""
            )

            arr_packages_to_install+="${str_packages_Required} "
            # </params>
        }

        # <summary> Select and Install software sorted by type. </summary>
        # <parameter name="${arr_packages_to_install[@]}"> arr: total list of packages to install </parameter>
        # <parameter name="${1}"> this list packages to install </parameter>
        # <parameter name="${2}"> output statement </parameter>
        # <returns> ${arr_packages_to_install[@]} </returns>
        function InstallFromLinuxRepos_InstallByType
        {
            if CheckIfVarIsValid "${1}"; then
                declare -i int_i=1
                local str_list_of_packages_to_install="${1}"
                local str_package=$( echo "${str_list_of_packages_to_install}" | cut -d ' ' -f "${int_i}" )

                while CheckIfVarIsValid $str_package; do
                    echo -e "\t${str_package}"
                    (( int_i++ ))
                    str_package=$( echo "${str_list_of_packages_to_install}" | cut -d ' ' -f "${int_i}" )
                done

                echo
                ReadInput "${2}" || return "${?}"
                arr_packages_to_install+=( "${str_list_of_packages_to_install}" )
                return 0
            fi

            return 1
        }

        function InstallFromLinuxRepos_Main
        {
            CheckIfVarIsValid "${str_package_manager}" || return "${?}"

            # <params>
            case "${str_package_manager}" in
                "apt" )
                    InstallFromLinuxRepos_GetParamsForAPT
                    ;;

                * )
                    return 1
                    ;;
            esac
            # </params>

            # <summary> Select and Install software sorted by type. </summary>
            InstallFromLinuxRepos_InstallByType ${arr_packages_Unsorted[@]} "Select given software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Commands[@]}  "Select Terminal commands?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Compatibilty[@]}  "Select compatibility libraries?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Developer[@]}  "Select Development software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Games[@]}  "Select games?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Internet[@]}  "Select Internet software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Media[@]}  "Select multi-media software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Office[@]}  "Select office software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_PrismBreak[@]}  "Select recommended \"Prism break\" software?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Repos[@]}  "Select software repositories?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Security[@]}  "Select security tools?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Suites[@]}  "Select software suites?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_Tools[@]}  "Select software tools?"
            InstallFromLinuxRepos_InstallByType ${arr_packages_VGA_drivers[@]}  "Select VGA drivers?"

            CheckIfVarIsValid ${arr_packages_to_install[@]} || return "${?}"
            ReadInput "Install selected packages?" && InstallPackage ${arr_packages_to_install[@]}
        }

        # <params>
        local readonly str_output="Installing from $( lsb_release -is ) $( uname -o ) repositories..."
        # </params>

        echo -e "${str_output}"
        InstallFromLinuxRepos_Main
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Install from Flathub software repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromFlathubRepos
    {
        # NOTE: Update Here!
        # <summary> Get params. </summary>
        # <returns> params </returns>
        function InstallFromFlathubRepos_GetParams
        {
            # <params>
            declare -a arr_flatpak_to_install=()

            declare -ar arr_flatpak_Compatibility=(
                "org.freedesktop.Platform"
                "org.freedesktop.Platform.Compat.i386"
                "org.freedesktop.Platform.GL.default"
                "org.freedesktop.Platform.GL32.default"
                "org.freedesktop.Platform.GL32.nvidia-460-91-03"
                "org.freedesktop.Platform.VAAPI.Intel.i386"
            )

            declare -ar arr_flatpak_Developer=(
                "com.visualstudio.code"
                "com.vscodium.codium"
            )

            declare -ar arr_flatpak_Games=(
                "org.libretro.RetroArch"
                "com.valvesoftware.Steam"
                "com.valvesoftware.SteamLink"
            )

            declare -ar arr_flatpak_Internet=(
                "org.filezillaproject.Filezilla"
                "io.gitlab.librewolf-community"
                "nz.mega.MEGAsync"
                "com.obsproject.Studio"
            )

            declare -ar arr_flatpak_Media=(
                "org.freedesktop.LinuxAudio.Plugins.TAP"
                "org.freedesktop.LinuxAudio.Plugins.swh"
                "com.stremio.Stremio"
                "org.videolan.VLC"
                "org.videolan.VLC.Plugin.makemkv"
            )

            declare -ar arr_flatpak_Office=(
                "org.libreoffice.LibreOffice"
                "org.mozilla.Thunderbird"
            )

            declare -ar arr_flatpak_PrismBreak=(
                "org.getmonero.Monero"
            )

            declare -ar arr_flatpak_Tools=(
                "org.openshot.OpenShot"
                "org.kde.digikam"
                "org.kde.kdenlive"
                "org.keepassxc.KeePassXC"
                "org.freedesktop.Platform.openh264"
                "org.freedesktop.Platform.ffmpeg-full"
                "org.bunkus.mkvtoolnix-gui"
                "com.adobe.Flash-Player-Projector"
                "com.calibre_ebook.calibre"
                "com.makemkv.MakeMKV"
                "com.poweriso.PowerISO"
                "fr.handbrake.ghb io.github.Hexchat"
            )

            declare -ar arr_flatpak_Unsorted=(
                "org.freedesktop.Sdk"
                "org.gnome.Platform"
                "org.gtk.Gtk3theme.Breeze"
                "org.kde.KStyle.Adwaita"
                "org.kde.Platform"
            )
            # </params>
        }

        # <summary> Select and Install software sorted by type. </summary>
        # <parameter name="${arr_flatpak_to_install[@]}"> total list of packages to install </parameter>
        # <parameter name="${1}"> this list packages to install </parameter>
        # <parameter name="${2}"> output statement </parameter>
        # <returns> ${arr_flatpak_to_install[@]} </returns>
        function InstallFromFlathubRepos_InstallByType
        {
            # <params>
            local str_package=""
            local var_command='echo "${str_list_of_packages_to_install}" | cut -d ' ' -f "${int_i}"'
            # </params>

            if CheckIfVarIsValid "${1}"; then
                declare -i int_i=1
                local str_list_of_packages_to_install="${1}"
                str_package=$( eval "${var_command}" )

                while CheckIfVarIsValid $str_package; do
                    echo -e "\t${str_package}"
                    (( int_i++ ))
                    str_package=$( eval "${var_command}" )
                done

                echo
                ReadInput "${2}" || return "${?}"
                arr_flatpak_to_install+=( "${str_list_of_packages_to_install}" )
                return 0
            fi

            return 1
        }

        function InstallFromFlathubRepos_Main
        {
            # <params>
            local str_command="flatpak"
            InstallFromFlathubRepos_GetParams
            # </params>

            CheckIfCommandIsInstalled "${str_command}" || (
                InstallPackage "${str_command}"
                CheckIfCommandIsInstalled "${str_command}" || return "${?}"
            )

            # <summary> Pre-requisites. </summary>
            local str_packages="plasma-desktop lxqt"
            local str_packages_dependencies="plasma-discover-backend-flatpak"
            CheckIfCommandIsInstalled "${str_packages}" || InstallPackage "${str_packages_dependencies}"

            local str_packages="gnome xfwm4"
            local str_packages_dependencies="gnome-software-plugin-flatpak"
            CheckIfCommandIsInstalled "${str_packages}" || InstallPackage "${str_packages_dependencies}"

            local readonly str_flatpak_repo="https://flathub.org/repo/flathub.flatpakrepo"

            sudo flatpak remote-add --if-not-exists flathub "${str_flatpak_repo}"
            sudo flatpak update -y || return 1
            echo

            # <summary> Select and Install software sorted by type. </summary>
            InstallFromFlathubRepos_InstallByType "${arr_flatpak_Unsorted[@]}" "Select given Flatpak software?"
            InstallFromFlathubRepos_InstallByType "${str_flatpak_PrismBreak[@]}" "Select recommended Prism Break Flatpak software?"
            CheckIfVarIsValid ${arr_flatpak_to_install[@]} || return "${?}"
            local readonly str_output="Install selected Flatpak apps?"
            ReadInput "${str_output}" && flatpak install --user "${arr_flatpak_to_install[@]}"
        }

        # <params>
        local readonly str_output="Installing from Flathub repositories..."
        # </params>

        echo -e "${str_output}"
        InstallFromFlathubRepos_Main
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Install from Git repositories. </summary>
    # <returns> exit code </returns>
    function InstallFromGitRepos
    {
        # NOTE: Update Here!
        # <summary> Set params. </summary>
        # <returns> params </returns>
        function InstallFromGitRepos_SetSudoScripts
        {
            # <summary> portellam/Auto-Xorg </summary>
            local str_file="installer.bash"
            local str_repo="portellam/auto-xorg"
            local str_scriptDir="${str_dir1}${str_repo}/"
            InstallFromGitRepos_ExecuteScript $str_scriptDir "${str_file}"

            # <summary> StevenBlack/hosts </summary>
            local str_repo="stevenblack/hosts"
            local str_scriptDir="${str_dir1}${str_repo}/"
            echo -e "Executing script '${str_repo}'"

            if CheckIfDirExists $str_scriptDir; then
                cd $str_scriptDir
                local str_file="/etc/hosts"

                CreateBackupFile "${str_file}" && ( cp hosts "${str_file}" &> /dev/null || bool_nonzero_amount_of_failed_operations=false )
            fi

            # <summary> pyllyukko/user.js </summary>
            local str_repo="pyllyukko/user.js"
            local str_scriptDir="${str_dir1}${str_repo}/"
            echo -e "Executing script '${str_repo}'"

            if CheckIfDirExists $str_scriptDir; then
                cd $str_scriptDir
                local str_file1="/etc/firefox-esr/firefox-esr.js"

                make debian_locked.js &> /dev/null && (
                    CreateBackupFile "${str_file}" && ( cp debian_locked.js "${str_file}" || bool_nonzero_amount_of_failed_operations=false )
                )
            fi

            # <summary> foundObjects/zram-swap </summary>
            local str_file="installer.sh"
            local str_repo="foundObjects/zram-swap"
            local str_scriptDir="${str_dir1}${str_repo}/"
            InstallFromGitRepos_ExecuteScript $str_scriptDir "${str_file}"
        }

        # NOTE: Update Here!
        # <summary> Set params. </summary>
        # <returns> params </returns>
        function InstallFromGitRepos_SetUserScripts
        {
            # <summary> awilliam/rom-parser </summary>
            # local str_file1="installer.sh"
            local str_repo="awilliam/rom-parser"
            local str_scriptDir="${str_dir1}${str_repo}/"
            # InstallFromGitRepos_ExecuteScript $str_scriptDir "${str_file}"
            # CheckIfDirExists $str_scriptDir

            # <summary> spaceinvaderone/Dump_GPU_vBIOS </summary>
            # local str_file1="installer.sh"
            local str_repo="spaceinvaderone/dump_gpu_vbios"
            local str_scriptDir="${str_dir1}${str_repo}/"
            # InstallFromGitRepos_ExecuteScript $str_scriptDir "${str_file}"
            # CheckIfDirExists $str_scriptDir

            # <summary> spheenik/vfio-isolate </summary>
            # local str_file1="installer.sh"
            local str_repo="spheenik/vfio-isolate"
            local str_scriptDir="${str_dir1}${str_repo}/"
            # InstallFromGitRepos_ExecuteScript $str_scriptDir "${str_file}"
            # CheckIfDirExists $str_scriptDir
        }

        # <summary> Prompt user to execute script or skip. </summary>
        # <parameter name="$bool"> check if any script failed to execute </parameter>
        # <parameter name="${1}"> script directory </parameter>
        # <parameter name="${2}"> script to execute </parameter>
        # <returns> exit code </returns>
        function InstallFromGitRepos_ExecuteScript
        {
            local readonly str_output="Executing Git script..."

            # <params>
            # local str_dir2=$( echo "${1}" | awk -F'/' '{print ${1}"/"${2}}' )
            local str_dir2=$( basename "${1}" )"/"
            # </params>

            cd "${str_dir}" || return 1
            ( CheckIfDirExists "${1}" && ( cd "${1}" || false ) ) || return "${?}"
            CheckIfFileExists ${2}|| return "${?}"

            if ReadInput "Execute script '${str_dir2}${2}'?"; then
                ( chmod +x "${2}" &> /dev/null ) || return 1
                CheckIfFileIsExecutable || return "${?}"

                if $bool_is_user_root; then
                    ( sudo bash "${2}" &> /dev/null ) || return "${?}"
                else
                    ( bash "${2}" &> /dev/null ) || return "${?}"
                fi
            fi

            AppendPassOrFail "${str_output}"
            cd "${str_dir}"1 || return 1
        }

        function InstallFromGitRepos_Main
        {
            # <params>
            local bool_nonzero_amount_of_failed_operations=false

            if $bool_is_user_root; then
                local readonly str_dir1="/root/source/"
            else
                local readonly str_dir1="~/source/"
            fi
            # </params>

            if CheckIfDirExists "${str_dir}"1; then
                if $bool_is_user_root; then
                    InstallFromGitRepos_SetSudoScripts
                else
                    InstallFromGitRepos_SetUserScripts
                fi
            fi

            $bool_nonzero_amount_of_failed_operations &> /dev/null && return "${int_code_partial_completion}"
            return 0
        }

        # <params>
        local readonly str_output="Executing Git scripts..."
        # </params>

        echo -e "${str_output}"
        InstallFromGitRepos_Main
        AppendPassOrFail "${str_output}"

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }

    # <summary> Setup software repositories for Debian Linux. </summary>
    # <returns> exit code </returns>
    function ModifyDebianRepos
    {
        function ModifyDebianRepos_Main
        {
            # <params>
            IFS=$'\n'
            local bool_nonzero_amount_of_failed_operations=false
            local readonly str_file="/etc/apt/sources.list"
            local readonly str_release_name=$( lsb_release -sc )
            local readonly str_release_Ver=$( lsb_release -sr )
            local str_sources=""
            # </params>

            CreateBackupFile "${str_file}" || return "${?}"
            local str_sources="contrib"
            ReadInput "Include '${str_sources}' sources?" && str_sources+="${str_sources}"
            CheckIfVarIsValid $str_sources &> /dev/null || str_sources+=" "
            local str_sources="non-free"
            ReadInput "Include '${str_sources}' sources?" && str_sources+="${str_sources}"

            # <summary> Setup mandatory sources. </summary>
            # <summary> User prompt </summary>
            echo
            echo -e "Repositories: Enter one valid option or none for default (Current branch: ${str_release_name})."
            echo -e "${str_prefix_warn}It is NOT possible to revert from a non-stable branch back to a stable or ${str_release_name} release branch."
            echo -e "Release branches:"
            echo -e "\t'stable'\t== '${str_release_name}'"
            echo -e "\t'testing'\t*more recent updates; slightly less stability"
            echo -e "\t'unstable'\t*most recent updates; least stability. NOT recommended."
            echo -e "\t'backports'\t== '${str_release_name}-backports'\t*optionally receive more recent updates."

            # <summary Apt sources </summary>
            ReadMultipleChoiceMatchCase "Enter option: " "stable" "testing" "unstable" "backports"
            local readonly str_branch_name=${var_return}

            declare -a arr_sources=(
                "# debian ${str_branch_name}"
                "# See https://wiki.debian.org/SourcesList for more information."
                "deb http://deb.debian.org/debian/ ${str_branch_name} main $str_sources"
                "deb-src http://deb.debian.org/debian/ ${str_branch_name} main $str_sources"
                $'\n'
                "deb http://deb.debian.org/debian/ ${str_branch_name}-updates main $str_sources"
                "deb-src http://deb.debian.org/debian/ ${str_branch_name}-updates main $str_sources"
                $'\n'
                "deb http://security.debian.org/debian-security/ ${str_branch_name}-security main $str_sources"
                "deb-src http://security.debian.org/debian-security/ ${str_branch_name}-security main $str_sources"
                "#"
            )

            CheckIfFileExists "${str_file1}" || bool_nonzero_amount_of_failed_operations=true

            # <summary> Comment out lines in system file. </summary>
            declare -a arr_file=()

            while read var_line; do
                if [[ "${var_line}" != "#"* ]]; then
                    var_line="#${var_line}"
                fi

                arr_file+=( "${var_line}" )
            done < "${str_file1}" || return 1

            WriteToFile "${str_file1}" "${arr_file[@]}"

            # <summary> Append to output. </summary>
            case "${str_branch_name}" in
                # <summary> Current branch with backports. </summary>
                "backports")
                    declare -a arr_sources=(
                        "# debian $str_release_Ver/$str_release_name"
                        "# See https://wiki.debian.org/SourcesList for more information."
                        "deb http://deb.debian.org/debian/ $str_release_name main $str_sources"
                        "deb-src http://deb.debian.org/debian/ $str_release_name main $str_sources"
                        ""
                        "deb http://deb.debian.org/debian/ $str_release_name-updates main $str_sources"
                        "deb-src http://deb.debian.org/debian/ $str_release_name-updates main $str_sources"
                        ""
                        "deb http://security.debian.org/debian-security/ $str_release_name-security main $str_sources"
                        "deb-src http://security.debian.org/debian-security/ $str_release_name-security main $str_sources"
                        "#"
                        ""
                        "# debian $str_release_Ver/$str_release_name ${str_branch_name}"
                        "deb http://deb.debian.org/debian $str_release_name-${str_branch_name} main contrib non-free"
                        "deb-src http://deb.debian.org/debian $str_release_name-${str_branch_name} main contrib non-free"
                        "#"
                    )
                    ;;
            esac

            # <summary> Output to sources file. </summary>
            local readonly str_file2="/etc/apt/sources.list.d/${str_branch_name}.list"
            # DeleteFile $str_file2 &> /dev/null
            # CreateFile $str_file2 &> /dev/null

            case "${str_branch_name}" in
                "backports"|"testing"|"unstable" )
                    declare -a arr_file=( "${arr_sources[@]}" )
                    WriteToFile "${str_file1}" "${arr_file[@]}"
                    ;;
            esac

            # <summary> Update packages on system. </summary>
            apt clean || bool_nonzero_amount_of_failed_operations=true
            apt update || return 1
            apt full-upgrade || return 1

            $bool_nonzero_amount_of_failed_operations &> /dev/null && return "${int_code_partial_completion}"
            return 0
        }

        # <params>
        local readonly str_distro="$( lsb_release -is ) "
        local readonly str_kernel="$( uname -o ) "
        local readonly str_output="Modifying ${str_distro}${str_kernel}repositories..."
        # </params>

        echo -e "${str_output}"
        ModifyDebianRepos_Main
        AppendPassOrFail "${str_output}"

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }

    # <summary> Configuration of SSH. </summary>
    # <parameter name="$str_alt_SSH"> string: chosen alternate SSH port value </parameter>
    # <returns> exit code </returns>
    function ModifySSH
    {
        function ModifySSH_Main
        {
            # <params>
            local bool=true
            local str_command="ssh"
            declare -ir int_min_count=1
            declare -ir int_max_count=3
            declare -ar arr_count=$( eval echo {$int_min_count..$int_max_count} )
            declare -a arr_file=()
            # </params>

            local str_output="Modify SSH?"

            if ! ReadInput "${str_output}"; then
                return "${int_code_skipped_operation}"
            else
                local readonly int_port_min=22
                local readonly int_port_max=65536
                local str_output="Enter a new IP Port number for SSH (leave blank for default)."

                for int_count in ${arr_count[@]}; do
                    ReadInputFromRangeOfTwoNums "${str_output}" "${int_port_min}" "${int_port_max}"
                    declare -i int_alt_SSH="${var_input}"

                    if [[ "${int_alt_SSH}" -eq "${int_port_min}" || $int_alt_SSH -gt "${int_port_max}" ]]; then
                        str_alt_SSH="${int_alt_SSH}"
                        break
                    fi

                    echo -e "${str_prefix_warn}Available port range: 10000-65535"
                done
            fi

            if [[ "${str_alt_SSH}" -eq "${int_port_min}" ]]; then
                bool=false
            fi

            arr_file+=(
                "#"
                "LoginGraceTime 1m"
                "PermitRootLogin prohibit-password"
                "MaxAuthTries 6"
                "MaxSessions 2"
            )

            if $bool; then
                arr_file+=(
                    "Port ${str_alt_SSH}"
                )
            fi

            if CheckIfCommandIsInstalled "${str_command}"; then
                local readonly str_file1="/etc/ssh/ssh_config"
                CreateBackupFile "${str_file1}" || return "${?}"
                # TODO: refactor, do this action once for all related files for given related commands.  $bool_is_connected_to_Internet && ( DeleteFile "${str_file1}" || return "${?}" )
                $bool_is_connected_to_Internet && ( DeleteFile "${str_file1}" || return "${?}" )

                # <summary> Reinstall package to regenerate system configuration file. </summary>
                case "${str_package_manager}" in
                    "apt" )
                        local str_package_to_install="openssh-client"
                        ;;

                    * )
                        return 1
                        ;;
                esac

                if $bool_is_connected_to_Internet && ! InstallPackage "${str_package_to_install}" true; then
                    RestoreBackupFile "${str_file1}"
                    return "${?}"
                fi

                WriteToFile "${str_file1}" "${arr_file[@]}" || return "${?}"
                systemctl restart "${str_command}" || return 1
            fi

            SaveExitCode
            str_command="sshd"

            # if CheckIfCommandIsInstalled "${str_command}"; then
            #     local readonly str_file1="/etc/ssh/sshd_config"
            #     CreateBackupFile "${str_file1}" || return "${?}"
            #     $bool_is_connected_to_Internet && ( DeleteFile "${str_file1}" || return "${?}" )

            #     # <summary> Reinstall package to regenerate system configuration file. </summary>
            #     case "${str_package_manager}" in
            #         "apt" )
            #             local str_package_to_install="openssh-client"
            #             ;;

            #         * )
            #             return 1
            #             ;;
            #     esac

            #     if $bool_is_connected_to_Internet && ! InstallPackage "${str_package_to_install}" true; then
            #         RestoreBackupFile "${str_file1}"
            #         return "${?}"
            #     fi

            #     WriteToFile "${str_file1}" "${arr_file[@]}" || return "${?}"
            #     systemctl restart "${str_command}" || return 1
            # fi

            SaveExitCode
            return "${int_exit_code}"
        }

        # <params>
        local readonly str_output="Configuring SSH..."
        # </params>

        echo -e "${str_output}"
        ModifySSH_Main
        AppendPassOrFail "${str_output}"
        return "${int_exit_code}"
    }

    # <summary> Recommended host security changes. </summary>
    # <returns> exit code </returns>
    function ModifySecurity
    {
        # <summary> Modify system files for security. </summary>
        # <returns> exit code </returns>
        function ModifySecurity_AppendFiles
        {
            local readonly str_output="Disable given device interfaces (for storage devices only): USB, Firewire, Thunderbolt?"

            if ReadInput "${str_output}"; then
                local str_file="/etc/modprobe.d/disable-usb-storage.conf"
                declare -a arr_file=(
                    'install usb-storage /bin/true'
                )

                DeleteFile "${str_file}" &> /dev/null || return "${?}"
                WriteToFile "${str_file}" "${arr_file[@]}" || return "${?}"

                local str_file="/etc/modprobe.d/disable-firewire.conf"
                declare -a arr_file=(
                    'blacklist firewire-core'
                )

                DeleteFile "${str_file}" &> /dev/null || return "${?}"
                WriteToFile "${str_file}" "${arr_file[@]}" || return "${?}"

                local str_file="/etc/modprobe.d/disable-thunderbolt.conf"
                declare -a arr_file=(
                    'blacklist thunderbolt'
                )

                DeleteFile "${str_file}" &> /dev/null || return "${?}"
                WriteToFile "${str_file}" "${arr_file[@]}" || return "${?}"

                update-initramfs -u -k all || return "${?}"
            fi
        }

        # NOTE: Update Here!
        # <summary> Get params. </summary>
        # <returns> params </returns>
        function ModifySecurity_GetPackages
        {
            # <params>
            local readonly arr_params=(
                "atftpd"
                "nis"
                "rsh-redone-server"
                "rsh-server"
                "telnetd"
                "tftpd"
                "tftpd-hpa"
                "xinetd"
                "yp-tools"
            )
            # </params>

            echo -e "${arr_params[@]}"
        }

        # NOTE: Update Here!
        # <summary> Get params. </summary>
        # <returns> params </returns>
        function ModifySecurity_GetServices
        {
            # <params>
            local readonly arr_params=(
                "apcupsd"
                "cockpit"
                "fail2ban"
                "ssh"
                "ufw"
            )
            # </params>

            echo -e "${arr_params[@]}"
        }

        # NOTE: Update Here!
        # <summary> Services to Enable or Disable (security-benefits or risks). </summary>
        # <returns> exit code </returns>
        function ModifySecurity_SetupFirewall
        {
            # <params>
            local str_command="ufw"
            # </params>

            CheckIfCommandExists "${str_command}" || return "${?}"
            ufw reset || return 1
            ufw default allow outgoing || return 1
            ufw default deny incoming || return 1

            # <summary> Default LAN subnets may be 192.168.1.0/24 </summary>
            # <summary> Services a desktop may use. Attempt to make changes. Exit early at failure. </summary>
            ( ufw allow DNS comment 'dns' &> /dev/null ) || return 1
            ( ufw allow from 192.168.0.0/16 to any port 137:138 proto udp comment 'CIFS/Samba, local file server' &> /dev/null ) || return 1
            ( ufw allow from 192.168.0.0/16 to any port 139,445 proto tcp comment 'CIFS/Samba, local file server' &> /dev/null ) || return 1
            ( ufw allow from 192.168.0.0/16 to any port 2049 comment 'NFS, local file server' &> /dev/null ) || return 1
            ( ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP, local remote desktop server' &> /dev/null ) || return 1
            ( ufw allow VNC comment 'VNC, local remote desktop server' &> /dev/null ) || return 1
            ( ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment 'Cockpit, local Web server' &> /dev/null ) || return 1

            # <summary> Services a server may use. Attempt to make changes. Exit early at failure. </summary>
            ( ufw allow http comment 'HTTP, local Web server' &> /dev/null ) || return 1
            ( ufw allow https comment 'HTTPS, local Web server' &> /dev/null ) || return 1
            ( ufw allow 25 comment 'SMTPD, local mail server' &> /dev/null ) || return 1
            ( ufw allow 110 comment 'POP3, local mail server' &> /dev/null ) || return 1
            ( ufw allow 995 comment 'POP3S, local mail server' &> /dev/null ) || return 1
            ( ufw allow 1194/udp 'SMTPD, local VPN server' &> /dev/null ) || return 1

            # <summary> SSH on LAN </summary>
            str_command="ssh"

            if CheckIfCommandIsInstalled "${str_command}"; then
                # ModifySSH

                if CheckIfVarIsValidNum $str_alt_SSH; then
                    ( ufw deny ssh comment 'deny default ssh' &> /dev/null ) || return 1
                    ( ufw limit from 192.168.0.0/16 to any port ${str_alt_SSH} proto tcp comment 'ssh' &> /dev/null ) || return 1
                else
                    ( ufw limit from 192.168.0.0/16 to any port 22 proto tcp comment 'ssh' &> /dev/null ) || return 1
                fi

                ( ufw deny ssh comment 'deny default ssh' &> /dev/null ) || return 1
            fi

            ( ufw enable &> /dev/null ) || return 1
            ( ufw reload &> /dev/null ) || return 1

            return 0
        }

        # <summary> Software packages to uninstall. </summary>
        # <returns> exit code </returns>
        function ModifySecurity_SetupPackages
        {
            # <params>
            declare -a arr_packages=()
            declare -a arr_packages_to_uninstall=()
            local readonly str_packages=$( ModifySecurity_GetPackages )
            local readonly var_delimiter=' '
            # </params>

            if readarray -t -d ${var_delimiter} <<< ${str_packages} &> /dev/null; then
                readonly arr_packages=( "${MAPFILE[@]}" )
            fi

            CheckIfVarIsValid "${arr_packages[@]}" || return "${?}"

            for str_package in ${arr_packages}; do
                if CheckIfCommandIsInstalled "${str_package}" &> /dev/null; then
                    local str_output="Uninstall '${str_package}'?"

                    if ReadInput "${str_output}"; then
                        arr_packages_to_uninstall+=( "${str_package}" )
                    fi
                fi
            done

            UninstallPackage "${arr_packages_to_uninstall[@]}" || return "${?}"
            return 0
        }

        # <summary> Services to Enable or Disable (security-benefits or risks). </summary>
        # <returns> exit code </returns>
        function ModifySecurity_SetupServices
        {
            # <params>
            declare -a arr_services=()
            declare -a arr_services_to_disable=()
            declare -a arr_services_to_enable=()
            local readonly str_services=$( ModifySecurity_GetServices )
            local readonly var_delimiter=' '
            # </params>

            if readarray -t -d ${var_delimiter} <<< ${str_services} &> /dev/null; then
                readonly arr_services=( "${MAPFILE[@]}" )
            fi

            CheckIfVarIsValid "${arr_services[@]}" || return "${?}"

            for str_service in ${arr_services}; do
                if CheckIfCommandIsInstalled "${str_service}" &> /dev/null; then
                    local str_output="Enable or Disable '${str_service}'?"

                    if ReadInput "${str_output}"; then
                        arr_services_to_enable+=( "${str_service}" )
                    else
                        arr_services_to_disable+=( "${str_service}" )
                    fi
                fi
            done

            systemctl stop "${arr_services_to_disable[@]}" && systemctl disable "${arr_services_to_disable[@]}" || return 1
            systemctl start "${arr_services_to_enable[@]}" && systemctl disable "${arr_services_to_enable[@]}" || return 1
            return 0
        }

        function ModifySecurity_Main
        {
            # <params>
            local bool_nonzero_amount_of_failed_operations=false
            local readonly str_file1="${str_files_dir}sysctl.conf"
            local readonly str_file2="/etc/${str_file1}"
            # </params>

            CheckIfDirExists "${str_file1}" || return "${?}"
            ModifySecurity_SetupPackages || bool_nonzero_amount_of_failed_operations=true
            ModifySecurity_SetupServices || bool_nonzero_amount_of_failed_operations=true
            ModifySecurity_AppendFiles || bool_nonzero_amount_of_failed_operations=true

            if CheckIfFileExists "${str_file1}"; then
                local str_output="Setup '${str_file2}' with defaults?"

                if ReadInput "${str_output}"; then
                    ( cp "${str_file1}" "${str_file2}" &> /dev/null ) || return "${?}"
                    ( cat "${str_file2}" >> "${str_file1}" &> /dev/null ) || return "${?}"
                fi
            fi

            local str_output="Setup firewall with UFW?"
            ReadInput "${str_output}" && ModifySecurity_SetupFirewall || return "${?}"
            $bool_nonzero_amount_of_failed_operations &> /dev/null && return "${int_code_partial_completion}"
            return 0
        }

        # <params>
        local str_output="Configuring system security..."
        # </params>

        echo -e "${str_output}"
        ModifySecurity_Main
        AppendPassOrFail "${str_output}"
        GoToScriptDir

        if [[ "${int_exit_code}" -eq "${int_code_partial_completion}" ]]; then
            echo -e "${str_output_partial_completion}"
        fi

        return "${int_exit_code}"
    }
# </code>

# <summary> Program middleman logic </summary>
# <code>
    # <summary> Display Help to console. </summary>
        # <returns> exit code </returns>
        # function Help
        # {
        #     declare -r str_helpPrompt="Usage: "${0}" [ OPTIONS ]
        #         \nwhere OPTIONS
        #         \n\t-h  --help\t\t\tPrint this prompt.
        #         \n\t-d  --delete\t\t\tDelete existing VFIO setup.
        #         \n\t-w  --write <logfile>\t\tWrite output (IOMMU groups) to <logfile>
        #         \n\t-m  --multiboot <ARGUMENT>\tExecute Multiboot VFIO setup.
        #         \n\t-s  --static <ARGUMENT>\t\tExecute Static VFIO setup.
        #         \n\nwhere ARGUMENTS
        #         \n\t-f  --full\t\t\tExecute pre-setup and post-setup.
        #         \n\t-r  --read <logfile>\t\tRead previous output (IOMMU groups) from <logfile>, and update VFIO setup.
        #         \n"

        #     echo -e $str_helpPrompt

        #     ExitWithThisExitCode
        # }

        # <summary> Parse input parameters for given options. </summary>
        # <returns> exit code </returns>
        # function ParseInputParamForOptions
        # {
        #     if [[ "${1}" =~ ^- || "${1}" == "--" ]]; then           # parse input parameters
        #         while [[ "${1}" =~ ^-  ]]; do
        #             case "${1}" in
        #                 "")                                     # no option
        #                     SetExitCodeOnError
        #                     SaveExitCode
        #                     break;;

        #                 -h | --help )                           # options
        #                     declare -lir int_aFlag=1
        #                     break;;
        #                 -d | --delete )
        #                     declare -lir int_aFlag=2
        #                     break;;
        #                 -m | --multiboot )
        #                     declare -lir int_aFlag=3;;
        #                 -s | --static )
        #                     declare -lir int_aFlag=4;;
        #                 -w | --write )
        #                     declare -lir int_aFlag=5;;

        #                 -f | --full )                           # arguments
        #                     declare -lir int_bFlag=1;;
        #                 -r | --read )
        #                     declare -lir int_bFlag=2;;
        #             esac

        #             shift
        #         done
        #     else                                                # invalid option
        #         SetExitCodeOnError
        #         SaveExitCode
        #         ParseThisExitCode
        #         Help
        #         ExitWithThisExitCode
        #     fi

        #     # if [[ "${1}" == '--' ]]; then
        #     #     shift
        #     # fi

        #     case $int_aFlag in                                  # execute second options before first options
        #         3|4)
        #             case $int_bFlag in
        #                 1)
        #                     PreInstallSetup;;
        #                 # 2)
        #                 #     ReadIOMMU_FromFile;;
        #             esac;;
        #     esac

        #     case $int_aFlag in                                  # execute first options
        #         1)
        #             Help;;
        #         2)
        #             DeleteSetup;;
        #         3)
        #             MultiBootSetup;;
        #         4)
        #             StaticSetup;;
        #         # 5)
        #         #     WriteIOMMU_ToFile;;
        #     esac

        #     case $int_aFlag in                                  # execute second options after first options
        #         3|4)
        #             case $int_bFlag in
        #                 1)
        #                     PostInstallSetup;;
        #             esac;;
        #     esac
        # }
    #

    # <summary> Execute setup of recommended and optional system changes. </summary>
    # <returns> exit code </returns>
    function ExecuteSystemSetup
    {
        # <params>
        declare -g str_alt_SSH=""
        # </params>

        if $bool_is_user_root; then
            ModifySSH
            ModifySecurity || return "${?}"
            AppendServices || return "${?}"
            AppendCron || return "${?}"
        fi
    }

    # <summary> Execute setup of all software repositories. </summary>
    # <returns> exit code </returns>
    function ExecuteSoftwareSetup
    {
        local readonly str_disclaimer="${str_prefix_warn}If system update is/was prematurely stopped, to restart progress, execute in terminal:\t${var_yellow}'sudo dpkg --configure -a'${var_reset_color}"

        if $bool_is_user_root; then
            case "${str_package_manager}" in
                "apt" )
                    ModifyDebianRepos || return "${?}"
                    ;;
            esac
        fi

        local var_command="TestNetwork true"
        TryThisXTimesBeforeFail "${var_command}" || return "${?}"

        if $bool_is_user_root; then
            InstallFromLinuxRepos || return "${?}"
        else
            InstallFromFlathubRepos || return "${?}"
        fi

        echo -e "${str_disclaimer}"
    }

    # <summary> Execute setup of GitHub repositories (of which that are executable and installable). </summary>
    # <returns> exit code </returns>
    function ExecuteGitSetup
    {
        # <params>
        local bool=false
        local readonly str_command="git"
        # </params>

        TryThisXTimesBeforeFail "TestNetwork true"|| return "${?}"

        if CheckIfCommandIsInstalled "${str_command}" &> /dev/null; then
            bool=true
        else
            ( InstallPackage "${str_command}" && bool=true ) || return "${?}"
        fi

        if $bool; then
            CloneOrUpdateGitRepositories || return "${?}"
            InstallFromGitRepos || return "${?}"
        fi
    }
# </code>

# <summary> Program Main logic </summary>
# <code>
    # <params>
    GoToScriptDir; declare -gr str_files_dir="$( find . -name files | uniq | head -n1 )/"
    declare -g bool_is_connected_to_Internet=false
    TryThisXTimesBeforeFail "TestNetwork true" &> /dev/null && bool_is_connected_to_Internet=true

    # NOTE: Update Here!
    declare -gr str_functions_to_execute='ExecuteSystemSetup|ExecuteGitSetup|ExecuteSoftwareSetup'
    declare -gr str_functions_to_execute_output='Execute System setup?|Execute Git setup and installation?|Execute software setup and installation?'
    # </params>

    ParseAndExecuteListOfCommands "${str_functions_to_execute}" "${str_functions_to_execute_output}"
    exit "${int_exit_code}"
# </code>