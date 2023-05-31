#!/bin/bash

set -e

function usage ()
{
    echo "Usage: $0 [-s <server name>] [-u <user name>] [-p <password>] [-d <directory>] [-t <target dir>]" 1>&2
    exit 1
}

directory="$(pwd)"
target="$(date -Id)"

while getopts ":s:u:p:d:t:" key; do
    case "${key}" in
        s)
            server_name="${OPTARG}"
            ;;
        u)
            user_name="${OPTARG}"
            ;;
        p)
            password="${OPTARG}"
            ;;
        d)
            directory="${OPTARG}"
            ;;
        t)
            target="${OPTARG}"
            ;;
        *)
            usage
            ;;
    esac
done

# checks for correct installation
if [ ! $(docker -v | grep -c -w version) -eq 1 ]; then
	echo "docker not found."
	exit 1
fi
if [ ! $(groups | grep -c -w docker) -eq 1 ]; then
	echo "add current user $(whoami) to docker group!"
	exit 1
fi

top_level=$(git rev-parse --show-toplevel)

# build containter
echo "##[group]Build Docker container 'ftp-upload'"
docker build --build-arg FTP_SERVER=$server_name -t ftp-upload $top_level/tools/ftp-upload
echo "##[endgroup]"

# upload
echo "##[group]Upload files using ftp"
docker run --rm -v "$directory:/data" ftp-upload \
    lftp -e "set ssl:verify-certificate no; mirror --verbose=3 -R /data \"$target\"; quit" \
        -u "$user_name,$password" $server_name
echo "##[endgroup]"
