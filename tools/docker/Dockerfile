FROM debian:buster
MAINTAINER Matthias J. Kastner matthias.kastner@byte-physics.de

# download appropriate packages
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && \
	apt-get install -y \
		doxygen \
		gawk \
		git \
		graphviz \
		python3 \
		python3-pip \
		zip && \
	apt-get clean

# download appropriate packages
# * html image generator from dvipng
# * latex command from latexmk
# * utf8x.def from texlive-latex-extra
RUN DEBIAN_FRONTEND=noninteractive \
	apt-get update && \
	apt-get install -y \
		dvipng \
		latexmk \
		texlive-latex-extra && \
	apt-get clean

# install packages via pip
RUN DEBIAN_FRONTEND=noninteractive \
	pip3 install \
		'breathe==4.12.0' \
		'sphinx==1.8.5' \
		sphinxcontrib-fulltoc \
		sphinxcontrib-images
