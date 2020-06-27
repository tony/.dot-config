#!/bin/sh

if [ -f /usr/bin/yarn -a -d $HOME/.yarn/bin ]; then
    # pathprepend $HOME/.yarn/bin 
    pathprepend `yarn global bin`
fi
