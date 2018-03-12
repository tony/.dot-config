#!/bin/sh

if [ -d "$HOME/Library/Python/2.7/bin" ]; then
    pathprepend "$HOME/Library/Python/2.7/bin"
fi

if [ -d "$HOME/Library/Python/3.4/bin" ]; then
    pathprepend "$HOME/Library/Python/3.4/bin"
fi

if [ -d "{$HOME}/Library/Python/3.5/bin" ]; then
    pathprepend "$HOME/Library/Python/3.5/bin"
fi

if [ -d "{$HOME}/Library/Python/3.6/bin" ]; then
    pathprepend "$HOME/Library/Python/3.6/bin"
fi

if [ -d "$HOME/.local/bin" ]; then
    pathprepend "$HOME/.local/bin"
fi
