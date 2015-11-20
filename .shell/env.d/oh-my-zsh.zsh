#!/bin/zsh

## Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

_prep_zsh() {
    ZSH_THEME="lambda"
    export DISABLE_AUTO_TITLE="true"
    plugins=(git)
    source $ZSH/oh-my-zsh.sh
}
if [ -d $ZSH ]; then
    _prep_zsh
else
    curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
fi
