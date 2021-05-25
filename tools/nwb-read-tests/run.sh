#/bin/bash

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

bamboo_agent_home=$(echo "$top_level" | cut -d "/" -f -4)

list_of_files=$(find $top_level -iname "*-V2.nwb")

tag="nwb-read-tests"

# build containter
echo "Start building Docker container \"$tag\""

docker build --build-arg USERID=$(id -u)                     \
             --build-arg GROUPID=$(id -g)                    \
             --build-arg PACKAGE_WITH_VERSION="pynwb==1.5.1" \
             -t $tag $top_level/tools/nwb-read-tests

# use 'docker run -it ..' for interactive debugging
 docker run --rm -v $bamboo_agent_home:$bamboo_agent_home -v $top_level:/home/ci $tag python3 $top_level/tools/nwb-read-tests/nwbv2-read-test.py $list_of_files
