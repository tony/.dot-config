#!/bin/zsh

## Path to your oh-my-zsh configuration.
## Note this is used by the install.sh temporary, we don't recommend or understand
## why they didn't pick a more specific variable.
ZSH=$HOME/.oh-my-zsh

_prep_zsh() {
    export DISABLE_AUTO_TITLE="true"  # for tmuxp

    ZSH_THEME="pure"

    plugins=(git virtualenv)
    source $ZSH/oh-my-zsh.sh
}

# $ZSH could be populated from dotfiles --sync / setup of custom modules causing
# a race condition.  The custom modules in the dot-config may be symlinked before
# oh-my-zsh is created.
if [ -d $ZSH/.git ]; then
    _prep_zsh
else
    # ~/.oh-my-zsh/custom may already be populated, we need it out of the way
    if [ -d $ZSH ]; then
        mv $ZSH $HOME/.oh-my-zsh.bak
    fi

    curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh

    if [ -d $HOME/.dot-config/.oh-my-zsh/custom/ ]; then
        ln -s $HOME/.dot-config/.oh-my-zsh/custom/* $HOME/.oh-my-zsh/custom/
    fi
fi
