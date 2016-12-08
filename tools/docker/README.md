# Docker
## General
Docker is an open platform for distributed applications for developers and sysadmins.
Please visit http://www.docker.com for detailed information.
For installing docker see https://docs.docker.com/linux/ and chose the OS of your choice.
## Container
This docker container contains the latest doxygen version.
Actually it is not built directly from source but it is the latest build from the experimental branch of debian.
You would not want to install this directly on your machine. Therfor a container is the best solution. See https://wiki.debian.org/DebianExperimental for details on the experimental branch.
This container contains the basic operating system together with the following additional packages:
* doxygen
* gawk
* git
* graphviz (dot)
* zip

## Build the container
first you must build the container from the Dockerfile.
The container is not publicly hosted. Therefor we have to direct docker to the configuration file.
This is located in the subfolder docker-build-documentation.
Inside this directory run the doxygen-build script:
 docker build -t docker-build-documentation .
this fetches debian:experimental and installs the required building environment for doxygen
The docker image has only to be build on a change in the Dockerfile.

## Run Doxygen
After building the container it should be listed as an image.
 docker images
Shows the available images. If you see it listet here, you can build the doxygen documentation.
Please note, that in the following "/my/local/path" has to direct to the mies project directory.
On Windows use Brackets for the path: <C:\path\to\files>
 docker run -it --rm -v /my/local/path:/opt/mies docker-build-documentation /bin/sh /opt/mies/tools/build-documentation.sh
this command
* runs docker
* in interactive mode
* overwriting existing instances and
* links the local directory /my/local/path to /opt/mies in the container
* we previously named the container image 'docker-build-documentation'
* and we want to oben a shell (/bin/sh) in the container
* where the script build-documentation.sh is executed.

## Automation
also consider docker-build-documentation.sh for fully automating the above process.
