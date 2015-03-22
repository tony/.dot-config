#!/bin/sh

# rbenv
if [ -d $HOME/.rbenv/bin ]; then
    pathprepend $HOME/.rbenv/bin
    eval "$(rbenv init -)"
elif [ -f /usr/lib/rbenv/libexec/rbenv ]; then
    pathprepend /usr/lib/rbenv/libexec/
    eval "$(rbenv init -)"
fi
