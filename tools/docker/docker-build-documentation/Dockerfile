FROM debian:experimental
MAINTAINER Matthias J. Kastner matthias.kastner@byte-physics.de

# download appropriate packages
# @todo utf8x.def is missing in texlive-latex-base and *-full. skip latex
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && \
	apt-get install -y \
		doxygen \
		gawk \
		git \
		graphviz \
		pandoc \
		python \
		python-breathe \
		python-pip \
		python-sphinx \
		zip

# clear cache with downloaded packages
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get clean

# install packages via pip
RUN DEBIAN_FRONTEND=noninteractive \
	pip install -U sphinxcontrib-fulltoc

WORKDIR /opt/mies/tools/
