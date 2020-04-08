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

# build containter
echo "Start building Docker container 'mies-documentation'"
docker build --build-arg USERID=$(id -u) --build-arg GROUPID=$(id -g) -t mies-documentation $top_level/tools/docker

# execute build script
# use 'docker run -it ..' for interactive debugging
docker run --rm -v $HOME/bamboo-agent-home:/home/ci/bamboo-agent-home -v $top_level:/home/ci mies-documentation tools/build-documentation.sh
