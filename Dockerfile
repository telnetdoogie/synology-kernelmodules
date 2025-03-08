FROM ubuntu:latest

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

RUN mkdir /synology-toolkit
RUN mkdir /synology-toolkit/toolchains

WORKDIR /synology-toolkit
COPY platforms.json .
COPY entrypoint.sh .
COPY config_modification.json .

ENV PLATFORM=""

ENTRYPOINT ["/synology-toolkit/entrypoint.sh"]