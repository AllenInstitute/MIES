FROM debian:bookworm
LABEL org.opencontainers.image.authors="Thomas Braun thomas.braun@byte-physics.de"

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

RUN sed -ri 's/(main)/\1 contrib/g' /etc/apt/sources.list.d/debian.sources &&        \
    apt-get update &&                                                                \
    apt-get install --assume-yes --no-install-recommends                             \
        ca-certificates                                                              \
        ttf-mscorefonts-installer                                                    \
        wget &&                                                                      \
    wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb \
        -O packages-microsoft-prod.deb &&                                            \
    dpkg -i packages-microsoft-prod.deb &&                                           \
    rm packages-microsoft-prod.deb &&                                                \
    apt-get update &&                                                                \
    apt-get install -y dotnet-sdk-7.0 &&                                             \
    apt-get clean

RUN dotnet tool install --global --version 5.1.17 \
        dotnet-reportgenerator-globaltool && \
    mkdir -p /home/ci && \
    mv /root/.dotnet /home/ci

ENTRYPOINT [ "/home/ci/.dotnet/tools/reportgenerator" ]
