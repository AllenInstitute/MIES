FROM debian:buster
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&                                                                                              \
    apt-get install -y --no-install-recommends                                                                     \
      git                                                                                                          \
      python3-minimal                                                                                              \
      python3-pip                                                                                                  \
      python3-setuptools                                                                                           \
      python3-wheel                                                                                                \
      wget &&                                                                                                      \
      wget --quiet http://ftp.us.debian.org/debian/pool/main/w/what-is-python/python-is-python3_3.9.2-1_all.deb && \
      dpkg -i python-is-python3_3.9.2-1_all.deb &&                                                                 \
      rm -rf /var/lib/apt/lists/*
      # package python-is-python3 is only present in bullseye

ARG PACKAGE_WITH_VERSION

RUN pip3 install $PACKAGE_WITH_VERSION

RUN pip3 check

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $USERID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
