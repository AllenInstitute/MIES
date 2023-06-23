FROM debian:bullseye
MAINTAINER Thomas Braun thomas.braun@byte-physics.de

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&        \
    apt-get install --yes    \
        git                  \
        python3-minimal      \
        python3-pip          \
        python-is-python3 && \
    apt-get clean

RUN pip3 install pre-commit==2.20.0

ARG UID
ARG GID

# add normal user
RUN groupadd -g $GID ci
RUN useradd -u $UID -g $GID -ms /bin/bash ci

USER ci

WORKDIR /home/ci
