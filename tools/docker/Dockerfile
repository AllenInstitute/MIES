FROM debian:buster
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
      python2                      \
      python-pip                   \
      zip &&                       \
    apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
  pip2 install                     \
    breathe==4.11.0                \
    sphinx==1.8.3                  \
    sphinxcontrib-fulltoc==1.1     \
    sphinxcontrib-images==0.8.0

# [optional] IPNWB submodule script
#
# Packages/IPNWB/update_doc.sh

RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update &&                \
  apt-get install -y               \
    git                            \
    jq &&                          \
  apt-get clean

RUN DEBIAN_FRONTEND=noninteractive \
  pip2 install                     \
    json2yaml==1.1.1               \
    yq==2.10.0

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $USERID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
