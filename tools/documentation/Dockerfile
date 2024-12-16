FROM debian:bookworm
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&              \
    apt-get install -y             \
      doxygen                      \
      gawk                         \
      git                          \
      graphviz                     \
      pandoc                       \
      pip                          \
      python-is-python3            \
      python3                      \
      python3-setuptools           \
      python3-venv                 \
      zip &&                       \
    apt-get clean

ARG USERID
ARG GROUPID

# add normal user
RUN groupadd -g $GROUPID ci
RUN useradd -u $USERID -g $GROUPID -ms /bin/bash ci

USER ci

WORKDIR /home/ci

COPY requirements.txt .

# https://stackoverflow.com/a/75696359
RUN python -m venv --system-site-packages /home/ci/.venv && \
    . /home/ci/.venv/bin/activate                        && \
    pip3 install --no-deps -r requirements.txt

# https://stackoverflow.com/a/56286534
ENV PATH=${PATH}:/home/ci/.venv/bin
