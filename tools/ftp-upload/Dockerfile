FROM debian:bullseye
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y \
        ca-certificates \
        lftp \
        openssl && \
    apt-get clean

ARG UNAME=ci
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} -o ${UNAME} && \
    useradd -m -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}

USER ${UNAME}

RUN mkdir ~/.lftp                                             && \
    echo "set ssl:check-hostname false" >> ~/.lftp/rc         && \
    echo "set ftp:ssl-force true" >> ~/.lftp/rc               && \
    echo "set ftp:ssl-protect-data true" >> ~/.lftp/rc        && \
    echo "set ftp:ssl-protect-fxp true" >> ~/.lftp/rc         && \
    echo "set ftp:ssl-protect-list true" >> ~/.lftp/rc        && \
    echo "set mirror:parallel-directories true" >> ~/.lftp/rc && \
    echo "set mirror:parallel-transfer-count 5" >> ~/.lftp/rc
