#!/bin/sh

if command -v keychain > /dev/null 2>&1; then
    if [ -f $HOME/.ssh/id_rsa ]; then
        eval `keychain --quiet --stop others --inherit any --eval ~/.ssh/id_rsa`
    elif [ -f $HOME/.ssh/id_ed25519 ]; then
        eval `keychain --quiet --stop others --inherit any --eval ~/.ssh/id_ed25519`
    fi
fi
