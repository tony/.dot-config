#!/bin/sh


if [ -f $HOME/.perl5/perlbrew ];then
    export PERLBREW_ROOT=$HOME/.perl5/perlbrew
    source $PERLBREW_ROOT/etc/bashrc
fi
