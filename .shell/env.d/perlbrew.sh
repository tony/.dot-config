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
#
#
# cpanm:
#   perlbrew install-cpanm
#   cpanm --local-lib=$PERLBREW_ROOT local::lib && eval $(perl -I $PERLBREW_ROOT/lib/perl5/ -Mlocal::lib) 


if [ -d "$HOME/.perl5/perlbrew" ]; then
    export PERLBREW_ROOT=${1-$HOME/.perl5/perlbrew}
    . "$PERLBREW_ROOT/etc/bashrc"
fi
