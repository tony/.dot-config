#!/bin/sh

if [ -d $HOME/.linuxbrew ]; then
    # Until LinuxBrew is fixed, the following is required.
    # See: https://github.com/Homebrew/linuxbrew/issues/47
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
    ## Setup linux brew
    export LINUXBREWHOME=$HOME/.linuxbrew
    pathprepend $LINUXBREWHOME/bin:$LINUXBREWHOME/sbin
    export MANPATH=$LINUXBREWHOME/man:$MANPATH
    export PKG_CONFIG_PATH=$LINUXBREWHOME/lib64/pkgconfig:$LINUXBREWHOME/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=$LINUXBREWHOME/lib64:$LINUXBREWHOME/lib:$LD_LIBRARY_PATH
fi
