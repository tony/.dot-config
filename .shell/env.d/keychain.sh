#!/bin/sh

if command -v keychain > /dev/null 2>&1; then
    keychain ~/.ssh/id_rsa --quiet
fi
