#!/bin/sh
docker build -t compile_modules --build-arg PLATFORM=$1 .