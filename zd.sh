#!/bin/sh

if [ -z "$1" ]; then
    echo "Usage: $0 <file.zig> [args...]"
    exit 1
fi

SRC="$1"
shift
ARGS="$@"

NAME=$(echo "$SRC" | sed 's/.zig$//')

zig build-exe "$SRC" -O Debug
lldb ./$NAME -b -o "run $ARGS"