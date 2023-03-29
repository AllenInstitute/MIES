FROM debian:bullseye
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update &&              \
    apt-get install -y             \
      doxygen                      \
      gawk                         \
      git                          \
      graphviz                     \
      pandoc                       \
      python3                      \
      python3-pip                  \
      zip &&                       \
    apt-get clean

COPY requirements.txt .

RUN DEBIAN_FRONTEND=noninteractive \
  pip3 install -r requirements.txt

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $USERID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
