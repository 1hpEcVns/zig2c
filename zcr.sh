#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <file.zig>"
    exit 1
fi

SRC="$1"
BASENAME=$(echo "$SRC" | sed 's/.zig$//')

zig build-exe "$SRC" -ofmt=c > "${BASENAME}.c"
echo "Translated to ${BASENAME}.c (use clang manually to compile)"