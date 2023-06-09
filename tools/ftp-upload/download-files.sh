#!/bin/bash

set -e

function usage ()
{
    echo "Usage: $0 [-s <server name>] [-u <user name>] [-p <password>] [-d <local directory>] [-t <server dir>] [-i <include glob>] [-x <exclude glob>]" 1>&2
    exit 1
}

directory="$(pwd)"
target="$(date -Id)"
includeCnt=0
excludeCnt=0

while getopts ":s:u:p:d:t:i:x:" key; do
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
        i)
            include[$includeCnt]="${OPTARG}"
            includeCnt=$(( $includeCnt + 1 ))
            ;;
        x)
            exclude[$excludeCnt]="${OPTARG}"
            excludeCnt=$(( $excludeCnt + 1 ))
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
docker build \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    -t ftp-upload \
    $top_level/tools/ftp-upload
echo "##[endgroup]"

# upload
echo "##[group]Download files using ftp"
mkdir -p "$directory"
directory="$(realpath "$directory")"
command="set ssl:verify-certificate no; mirror --verbose=3 --continue"
for i in $(seq 0 $(( $includeCnt - 1 ))); do
    command="$command --include-glob=${include[$i]}"
done
for i in $(seq 0 $(( $excludeCnt - 1 ))); do
    command="$command --exclude-glob=${exclude[$i]}"
done
command="$command \"$target\" /data; quit"
docker run --rm -u $(id -u):$(id -g) -v "$directory:/data" ftp-upload \
    lftp -e "$command" \
        -u "$user_name,$password" $server_name
echo "##[endgroup]"

# output some variables (this makes CI integration easier)
if [ -f "$GITHUB_OUTPUT" ]; then
    echo "data=$directory" >> $GITHUB_OUTPUT
fi
