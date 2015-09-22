#!/bin/sh

# Customize to your needs...
# export PATH=$HOME/.local/bin:./node_modules/.bin:$HOME/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PATH


if [ -d $HOME/.node/bin ]; then
    pathprepend $HOME/.node/bin 
fi

if [ -d /usr/local/share/npm/lib/node_modules ]; then
    export NODE_PATH=/usr/local/share/npm/lib/node_modules
fi

if [ -d /usr/local/share/npm/bin ]; then
    pathprepend /usr/local/share/npm/bin
fi

pathprepend ./node_modules/.bin
