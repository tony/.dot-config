#!/bin/sh

if which yarn 1>/dev/null 2>&1; then
    # pathprepend $HOME/.yarn/bin
    pathprepend `yarn global bin`
fi
