#!/bin/zsh

_load_zprezto() {
    source ~/.zprezto/runcoms/zpreztorc
    source ~/.zprezto/init.zsh
    # Ensure that a non-login, non-interactive shell has a defined environment.
    # from sorin/ionescu/prezto
    if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
      source "${ZDOTDIR:-$HOME}/.zprofile"
    fi
}

if [ -d $HOME/.zprezto ]; then
    _load_zprezto
else
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" && _load_zprezto
fi
