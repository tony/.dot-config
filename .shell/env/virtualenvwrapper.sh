#!/bin/zsh

if [ -f $HOME/.local/bin/virtualenvwrapper.sh ]; then
    . $HOME/.local/bin/virtualenvwrapper.sh
elif [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
fi
