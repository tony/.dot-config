#!/bin/sh

if [ -d "${HOME}/.poetry" && -f "${HOME}/.poetry/env" ]; then
    source $HOME/.poetry/env
fi
