#!/bin/sh
#
# Before installation, set your PERLBREW_ROOT, or else it will default
# to $HOME/perl5/perlbrew
#
# export PERLBREW_ROOT=$HOME/.perl5/perlbrew;
#
# FreeBSD:
#     \fetch -o- http://install.perlbrew.pl | sh
#
# Linux:
#     curl -kL http://install.perlbrew.pl | bash


if [ -d "$HOME/.perl5/perlbrew" ]; then
    export PERLBREW_ROOT=${1-$HOME/.perl5/perlbrew}
    . "$PERLBREW_ROOT/etc/bashrc"
fi
