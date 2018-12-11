#!/bin/sh

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf'
alias clear_empty_dirs='find . -type d -empty -delete'

alias configure_vim='./configure --with-features=huge --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-luainterp --enable-gui --enable-multibyte'

# if [ -f /usr/local/bin/nvim ]; then
#     alias vim='/usr/local/bin/nvim'
# fi

export TTY=$(tty)

alias vim_git='vim -p $(git diff --name-only HEAD)'
