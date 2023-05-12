FROM debian:bullseye
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y \
        ca-certificates \
        lftp \
        openssl && \
    apt-get clean

ARG FTP_SERVER
RUN echo \
        | openssl s_client -servername ${FTP_SERVER} -connect ${FTP_SERVER}:21 -starttls ftp -prexit 2>&1 \
        | sed -ne '/-BEGIN\ CERTIFICATE-/,/-END\ CERTIFICATE-/p' \
        > /usr/local/share/ca-certificates/${FTP_SERVER}.crt && \
    update-ca-certificates
