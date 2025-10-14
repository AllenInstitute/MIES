#!/bin/bash

set -e

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

container_home="/home/ci"

# build containter
echo "##[group]Build Docker container 'pre-commit'"
docker build                     \
    --build-arg USERID=$(id -u)  \
    --build-arg GROUPID=$(id -g) \
    -t pre-commit                \
    $top_level/tools/pre-commit
echo "##[endgroup]"

echo "##[group]Running pre-commit"
docker run --rm -u $(id -u):$(id -g)                \
    --workdir=$container_home/repo                  \
    -v "$(pwd)/.cache:$container_home/.cache:rw"    \
    -v "$top_level:$container_home/repo" pre-commit \
    pre-commit run --all-files --show-diff-on-failure
echo "##[endgroup]"
