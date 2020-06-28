FROM ubuntu:18.04 as base

ENV DEBIAN_FRONTEND=noninteractive \
    METADATA_FILE=/image/metadata.txt \
    HELPER_SCRIPTS=/scripts/helpers

RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes && \
    mkdir /image && \ 
    mkdir agent && \
    touch /image/metadata.txt

RUN apt-get update && \
    apt-get install \
    apt-utils \
    lsb-release \ 
    lsb-core \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    sqlite \
    sqlite3

COPY scripts/base /scripts/base
COPY scripts/helpers /scripts/helpers
RUN chmod +x /scripts/base/* && chmod +x /scripts/helpers/*

# Commands from Base Image
RUN /scripts/base/preparemetadata.sh
RUN /scripts/base/basic.sh
RUN /scripts/base/repos.sh
RUN /scripts/helpers/apt.sh
RUN /scripts/base/7-zip.sh
RUN /scripts/base/azcopy.sh
RUN /scripts/base/gcc.sh
RUN /scripts/base/clang.sh
RUN /scripts/base/cmake.sh
RUN /scripts/base/build-essential.sh
RUN /scripts/base/azure-cli.sh
RUN /scripts/base/azure-devops-cli.sh

FROM base as docker
COPY scripts/docker /scripts/docker
RUN chmod +x /scripts/docker/*
RUN /scripts/docker/docker-moby.sh
RUN /scripts/docker/docker-compose.sh
RUN /scripts/docker/kubernetes-tools.sh

FROM docker as dotnet
COPY scripts/dotnet /scripts/dotnet
RUN chmod +x /scripts/dotnet/*
RUN /scripts/dotnet/dotnetcore-sdk.sh
RUN /scripts/dotnet/powershellcore.sh
RUN /scripts/dotnet/azpowershell.sh

FROM dotnet as nodejs
ENV AGENT_TOOLSDIRECTORY=/_work/_tool
COPY scripts/nodejs /scripts/nodejs
RUN chmod +x /scripts/nodejs/*
RUN /scripts/nodejs/nodejs.sh

FROM nodejs as extras
COPY scripts/extras /scripts/extras
RUN chmod +x /scripts/extras/*
RUN /scripts/extras/google-chrome.sh
RUN /scripts/extras/firefox.sh

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh
CMD ["./start.sh"]
