#!/bin/sh

# https://github.com/yyuu/pyenv-virtualenvwrapper/issues/19#issuecomment-54558646
# zprezto python module
if command -v pyenv > /dev/null 2>&1 && pyenv commands | grep -q "virtualenvwrapper"; then
    pyenv virtualenvwrapper_lazy
elif [ -f $HOME/.local/bin/virtualenvwrapper.sh ]; then
    . $HOME/.local/bin/virtualenvwrapper.sh
elif [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
fi
