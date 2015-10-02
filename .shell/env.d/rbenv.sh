#!/bin/sh

if [ -f /usr/local/libexec/rbenv ]; then # installed via freebsd ports pkg
    pathprepend /usr/local/libexec/rbenv/
    eval "$(rbenv init -)"
elif [ -d $HOME/.rbenv/bin ]; then
    pathprepend $HOME/.rbenv/bin
    eval "$(rbenv init -)"
elif [ -f /usr/lib/rbenv/libexec/rbenv ]; then
    pathprepend /usr/lib/rbenv/libexec/
    eval "$(rbenv init -)"
elif [ -f /usr/local/opt/rbenv/libexec/rbenv ]; then
    pathprepend /usr/local/opt/rbenv/libexec/
    eval "$(rbenv init -)"
fi



