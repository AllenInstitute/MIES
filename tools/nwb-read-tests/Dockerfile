FROM debian:bullseye
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&                          \
    apt-get install -y --no-install-recommends \
      git                                      \
      python-is-python3                        \
      python3-minimal                          \
      python3-pip                              \
      python3-setuptools                       \
      python3-wheel &&                         \
    rm -rf /var/lib/apt/lists/*

ARG PACKAGE_WITH_VERSION

RUN pip3 install $PACKAGE_WITH_VERSION

RUN pip3 check

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $GROUPID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
