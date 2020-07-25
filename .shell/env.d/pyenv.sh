#!/bin/sh

## pyenv paths
# curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
if [ -d "${HOME}/.pyenv" ]; then
    export PYENV_ROOT="${HOME}/.pyenv"
elif [ -d /usr/local/opt/pyenv ]; then
    pathprepend /usr/local/opt/pyenv/libexec/
    export PYENV_ROOT=/usr/local/opt/pyenv
fi

if [ -d "${PYENV_ROOT}" ]; then
    pathprepend ${PYENV_ROOT}/bin
    eval "$(pyenv init -)"
fi

if [ -d "/usr/local/opt/pyenv-virtualenv" ]; then
    pathprepend /usr/local/opt/pyenv-virtualenv/bin
    eval "$(pyenv virtualenv-init -)"
fi
