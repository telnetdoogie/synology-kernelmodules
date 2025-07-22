#!/bin/sh
docker run --privileged --rm \
    -v ./kernel_source:/kernel_source:rw \
    -v ./compiled_modules:/compiled_modules:rw \
    compile_modules