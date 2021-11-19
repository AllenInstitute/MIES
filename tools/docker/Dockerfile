FROM debian:bullseye
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

# MIES documentation script
#
# tools/build-documentation.sh

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

# [optional] IPNWB submodule script
#
# Packages/IPNWB/update_doc.sh

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update &&                \
  apt-get install -y               \
    jq &&                          \
  apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
  pip3 install                     \
    json2yaml==1.1.1               \
    yq==2.10.0

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $USERID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
