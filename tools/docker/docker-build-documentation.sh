#/bin/bash
# script checks for correct installation and executes build-documentation afterwards
# output is verbose
#
# check installation
if [ ! $(docker -v | grep -c -w version) -eq 1 ]; then
	echo "docker not found. installing."
	sudo apt-get -y -q install docker.io
fi
if [ ! $(groups | grep -c -w docker) -eq 1 ]; then
	echo "adding current user to docker group."
	sudo usermod -aG docker $(whoami)
	echo "please log off for changes to take affect."
	exit 0
fi
# build containter
echo "start building Docker container 'docker-build-documentation'"
docker build -qt docker-build-documentation -f docker-build-documentation/Dockerfile .
# run doxygen to see if correct version was installed
echo "Doxygen version" $(docker run -it --rm -v $(pwd)/../..:/opt/mies docker-build-documentation doxygen -v)
# execute build script (has to be executed from the docker-dir in ./tools/docker)
docker run -it --rm -v $(pwd)/../..:/opt/mies docker-build-documentation /bin/sh /opt/mies/tools/build-documentation.sh
