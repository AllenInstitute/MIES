FROM debian:buster
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update &&              \
    apt-get install -y             \
      python3                      \
      git                          \
      python3-pip &&               \
    apt-get clean

ARG PACKAGE_WITH_VERSION

RUN DEBIAN_FRONTEND=noninteractive \
    pip3 install $PACKAGE_WITH_VERSION

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $USERID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
