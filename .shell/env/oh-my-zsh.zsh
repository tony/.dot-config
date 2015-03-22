#!/bin/zsh

## Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
if [ -d $ZSH ]; then
    ZSH_THEME="steeef"
    export DISABLE_AUTO_TITLE="true"
    plugins=(git docker npm node brew brew-cask pip python)
    source $ZSH/oh-my-zsh.sh
fi
