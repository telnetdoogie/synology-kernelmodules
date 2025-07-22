FROM ubuntu:latest AS build-deps
RUN apt update
RUN apt install -y build-essential \
    ncurses-dev \
    bc \
    git \
    libssl-dev \
    libc6-i386 \
    curl \
    libproc-processtable-perl \
    wget \
    kmod \
    jq \
    cifs-utils \
    python3 \
    python3-pip \
    python-is-python3

FROM build-deps AS cross-deps
ARG PLATFORM
ENV PLATFORM=$PLATFORM
RUN mkdir -p /synology-toolkit /synology-toolkit/toolchains
WORKDIR /synology-toolkit
COPY platforms.json install.sh ./
RUN ./install.sh

COPY entrypoint.sh config_modification.json ./
ENTRYPOINT ["/synology-toolkit/entrypoint.sh"]