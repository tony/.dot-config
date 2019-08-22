#!/bin/sh

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf'
alias clear_empty_dirs='find . -type d -empty -delete'

# Thank you https://stackoverflow.com/a/1267524
alias my_internal_ip='python -c "import socket; print([l for l in ([ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] if not ip.startswith(\"127.\")][:1], [[(s.connect((\"8.8.8.8\", 53)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]]) if l][0][0])"'

alias configure_vim='./configure --with-features=huge --enable-pythoninterp --with-python-config-dir=/usr/lib/python2.7/config --enable-luainterp --enable-gui --enable-multibyte'

# if [ -f /usr/local/bin/nvim ]; then
#     alias vim='/usr/local/bin/nvim'
# fi

export TTY=$(tty)

alias vim_git='vim -p $(git diff --name-only HEAD)'
