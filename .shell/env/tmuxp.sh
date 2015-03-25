#!/bin/sh

if [ -n "$ZSH_VERSION" ] command -v tmuxp.zsh > /dev/null 2>&1; then
   source tmuxp.zsh
elif [ -n "$BASH_VERSION" ] command -v tmuxp.bash > /dev/null 2>&1; then
    source tmuxp.bash
fi
