FROM debian:bookworm
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&   \
    apt-get install -y  \
        ca-certificates \
        lftp            \
        openssl &&      \
    apt-get clean

ARG UNAME=ci
ARG USERID=1000
ARG GROUPID=1000

RUN groupadd -g ${GROUPID} -o ${UNAME} && \
    useradd -m -u ${USERID} -g ${GROUPID} -o -s /bin/bash ${UNAME}

USER ${UNAME}

RUN mkdir ~/.lftp                                             && \
    echo "set ssl:check-hostname false" >> ~/.lftp/rc         && \
    echo "set ftp:ssl-force true" >> ~/.lftp/rc               && \
    echo "set ftp:ssl-protect-data true" >> ~/.lftp/rc        && \
    echo "set ftp:ssl-protect-fxp true" >> ~/.lftp/rc         && \
    echo "set ftp:ssl-protect-list true" >> ~/.lftp/rc        && \
    echo "set mirror:parallel-directories true" >> ~/.lftp/rc && \
    echo "set mirror:parallel-transfer-count 5" >> ~/.lftp/rc
