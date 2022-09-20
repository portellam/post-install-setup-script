exit 0

# find family parent or child distro name #
        # NOTE: list is all encompassing #
        case $(lsb_release -is | tr '[:upper:]' '[:lower:]') in
        # case $(uname -a | tr '[:upper:]' '[:lower:]') in
        # case $(cat /etc/*-release | grep NAME | grep -Ev 'PRETTY|CODE' | tr '[:upper:]' '[:lower:]') in

            *"arch"*|*"manjaro"*)
                bool_distroIsArch=true;;

            *"debian"*|*"ubuntu"*|*"pop"*)
                bool_distroIsDebian=true;;

            *"fedora"*|*"redhat"*|*"oracle"*)
                bool_distroIsFedora=true;;

            *"gentoo"*)
                bool_distroIsGentoo=true;;

            *"suse"*)
                bool_distroIsSUSE=true;;

            *)
                echo -e "WARNING: Unrecognized Linux distribution. Continuing.";;
        esac