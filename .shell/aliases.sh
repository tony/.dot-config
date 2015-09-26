#!/bin/sh

alias clear_pyc='find . -name "*.pyc" -exec rm -rf {} \;'

alias configure_vim='./configure --with-features=huge --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-luainterp --enable-gui --enable-multibyte'

export TTY=$(tty)
