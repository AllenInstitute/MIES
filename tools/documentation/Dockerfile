FROM debian:bookworm
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&              \
    apt-get install -y             \
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

RUN mkdir -p /usr/local/bin

ADD --chown="$USERID":"$GROUPID" https://byte-physics.de/public-downloads/aistorage/transfer/ci/doxygen_1.14.0/doxygen /usr/local/bin
RUN chmod 0755 /usr/local/bin/doxygen
COPY sha256sum.lst .
RUN sha256sum -c sha256sum.lst

COPY requirements.txt .

# https://stackoverflow.com/a/75696359
RUN python -m venv --system-site-packages /home/ci/.venv && \
    . /home/ci/.venv/bin/activate                        && \
    pip3 install --no-deps -r requirements.txt

# https://stackoverflow.com/a/56286534
ENV PATH=${PATH}:/home/ci/.venv/bin
