#!/bin/sh

if command -v opam > /dev/null 2>&1; then
    if [ -d ~/.opam ]; then
        eval `opam config env`
    fi
fi
