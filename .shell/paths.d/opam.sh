#!/bin/sh

if [ -f ~/.opam/opam-init/init.zsh ]; then
    # OPAM configuration
    . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
fi
