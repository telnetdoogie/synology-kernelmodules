FROM ubuntu:latest
LABEL authors="jhobbs"

ENTRYPOINT ["top", "-b"]