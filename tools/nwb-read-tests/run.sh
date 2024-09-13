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

list_of_files=$(git ls-files --others '**/*V2.nwb')

tag="nwb-read-tests"

# build containter
echo "Start building Docker container \"$tag\""

docker build --build-arg USERID=$(id -u)                     \
             --build-arg GROUPID=$(id -g)                    \
             -t $tag $top_level/tools/nwb-read-tests

# use 'docker run -it ..' for interactive debugging
 docker run --rm --workdir /home/ci/src -v $top_level:/home/ci/src $tag python tools/nwb-read-tests/nwbv2-read-test.py $list_of_files
