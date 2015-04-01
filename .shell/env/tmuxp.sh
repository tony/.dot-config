#!/bin/sh

if [ -n "$ZSH_VERSION" ] && command -v tmuxp.zsh > /dev/null 2>&1; then
    if pyenv which tmuxp.zsh 1>/dev/null 2>&1; then
        source "$(pyenv which tmuxp.zsh)"
    else
        source tmuxp.zsh
    fi
elif [ -n "$BASH_VERSION" ] && command -v tmuxp.bash > /dev/null 2>&1; then
    if pyenv which tmuxp.bash 1>/dev/null 2>&1; then
        source "$(pyenv which tmuxp.bash)"
    else
        source tmuxp.bash
    fi
fi
