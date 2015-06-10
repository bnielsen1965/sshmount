#!/bin/bash

# default settings
MOUNT_OPTIONS="allow_other,default_permissions,idmap=user"
MOUNT_POINT=~/Mount
MOUNT_PATH=/var/www/html
MOUNT_USER=root
MOUNT_PASSWORD=
MOUNT_HOST=192.168.122.211
MOUNT_COMMAND=mount


# array to hold arguments without options
ARGV=()

PACKAGE=`basename $0`

# display usage help
function Usage()
{
    cat <<-ENDOFMESSAGE
$PACKAGE - mount filesystem over ssh

$PACKAGE [command] [mount point] [mount path] [options]

arguments:
command - the command to execute
mount point - the path to the mount point
mount path - the path on the remote server to mount

commands:
m or mount - mount the filesystem
u or umount - to unmount the filesystem
s or show - show the mount command that will be executed

options:
-h, --help show brief help
-u, --user MOUNT_USER the username for the ssh login
-H, --host MOUNT_HOST the hostname for the ssh login
-p, --password MOUNT_PASSWORD the password for the ssh login
-o, --options MOUNT_OPTIONS the options string to pass to fusermount

NOTES: 
This command requires the fuse-sshfs package.
The 'allow_other' option string value will require the /etc/fuse.conf option of 'user_allow_other'.
The filesystem host must be known. One solution is to use the show command and then mount the filesystem manually the first time and accept the fingerprint.
A MOUNT_PASSWORD setting is not required when using ssh keys.
ENDOFMESSAGE
exit
}


# die with message
function Die()
{
    echo "$* Use -h option to display help."
    exit 1
}


# process command line arguments into values to use
function ProcessArguments() {
    # separate options from arguments
    while [ $# -gt 0 ]
    do
        opt=$1
        shift
        case ${opt} in
            -u|--user)
                if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
                    Die "The ${opt} option requires an argument."
                fi
                export MOUNT_USER=$1
                shift
                ;;
            -H|--host)
                if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
                    Die "The ${opt} option requires an argument."
                fi
                export MOUNT_HOST=$1
                shift
                ;;
            -p|--password)
                if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
                    # read password input
                    echo -n Password: 
                    read -s password
                    echo
                    export MOUNT_PASSWORD=$password
                else
                    export MOUNT_PASSWORD=$1
                fi
                shift
                ;;
            -o|--options)
                if [ $# -eq 0 -o "${1:0:1}" = "-" ]; then
                    export MOUNT_OPTIONS=""
                else
                    export MOUNT_OPTIONS=$1
                fi
                shift
                ;;
            -h|--help)
                Usage;;
            *)
                if [ "${opt:0:1}" = "-" ]; then
                    Die "${opt}: unknown option."
                fi
                ARGV+=(${opt});;
        esac
    done

    # use command line arguments if provided
    if [ ${#ARGV[@]} -gt 0 ]; then
        export MOUNT_COMMAND=${ARGV[0]}
    fi

    if [ ${#ARGV[@]} -gt 1 ]; then
        export MOUNT_POINT=${ARGV[1]}
    fi

    if [ ${#ARGV[@]} -gt 2 ]; then
        export MOUNT_PATH=${ARGV[2]}
    fi

    # build the command that will be executed
    if [ -z "$MOUNT_OPTIONS" ]; then
        export EXEC_COMMAND="sshfs ${MOUNT_USER}@${MOUNT_HOST}:${MOUNT_PATH} ${MOUNT_POINT}"
    else
        export EXEC_COMMAND="sshfs ${MOUNT_USER}@${MOUNT_HOST}:${MOUNT_PATH} ${MOUNT_POINT} -o ${MOUNT_OPTIONS}"
    fi
}


# check to see if host is known
function CheckHostKnown() {
    if [ -z "$(ssh-keygen -F ${MOUNT_HOST})" ]; then
        Die "${MOUNT_HOST} unknown host. Manually setup host fingerprint."
    fi
}




# process command line arguments
ProcessArguments $*

#process command
case ${MOUNT_COMMAND} in
    s|show)
        echo "$EXEC_COMMAND"
        ;;
    m|mount)
        CheckHostKnown

        echo ${MOUNT_PASSWORD} | `$EXEC_COMMAND -o password_stdin`
        ;;
    u|umount)
        fusermount -u ${MOUNT_POINT}
        ;;
    *)
        Die "${MOUNT_COMMAND} is an unknown command."
        ;;
esac
