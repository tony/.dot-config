#!/bin/zsh

## Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh
ZSH_CUSTOM=$HOME/.config/oh-my-zsh/custom

_prep_zsh() {
    export DISABLE_AUTO_TITLE="true"  # for tmuxp

    ZSH_THEME="pure"

    plugins=(git virtualenv)
    source $ZSH/oh-my-zsh.sh
}
if [ -d $ZSH ]; then
    _prep_zsh
else
    curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
fi
