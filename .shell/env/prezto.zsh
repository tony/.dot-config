#!/bin/zsh

_load_zprezto() {
    source ~/.zprezto/runcoms/zpreztorc
    source ~/.zprezto/init.zsh
}

if [ -d $HOME/.zprezto ]; then
    _load_zprezto
else
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" && _load_zprezto
fi
