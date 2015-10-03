#!/bin/sh

if command -v keychain > /dev/null 2>&1; then
    eval `keychain --quiet --eval ~/.ssh/id_rsa`
fi
