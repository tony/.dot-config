#!/bin/sh

if [ -d "${HOME}/.poetry" -a -f "${HOME}/.poetry/env" ]; then
    source $HOME/.poetry/env
fi
