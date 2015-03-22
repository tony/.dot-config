#!/bin/zsh

_load_zprezto() {
    source ~/.zprezto/runcoms/zpreztorc
    zstyle ':prezto:module:prompt' theme 'steeef'
    source ~/.zprezto/init.zsh
}

if [ -d $HOME/.zprezto ]; then
    _load_zprezto
else
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" && _load_zprezto
fi
