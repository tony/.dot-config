#!/bin/zsh

source $HOME/.dot-config/.sh_functions.sh

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

ZSH_THEME="steeef"

export DISABLE_AUTO_TITLE="true"

plugins=(git docker npm node brew brew-cask pip python)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
# export PATH=$HOME/.local/bin:./node_modules/.bin:$HOME/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PATH
pathprepend $HOME/.local/bin ./node_modules/.bin $HOME/bin /usr/lib/lightdm/lightdm /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/games /usr/local/games $PATH

if [ -d /usr/local/share/npm/lib/node_modules ]; then
    export NODE_PATH=/usr/local/share/npm/lib/node_modules
fi

if [ -d /usr/local/share/npm/bin ]; then
    pathprepend /usr/local/share/npm/bin
fi

# rbenv
if [ -d $HOME/.rbenv/bin ]; then
    pathprepend $HOME/.rbenv/bin
    eval "$(rbenv init -)"
elif [ -f /usr/lib/rbenv/libexec/rbenv ]; then
    pathprepend /usr/lib/rbenv/libexec/
    eval "$(rbenv init -)"
fi

## pyenv paths
# curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
if [ -d "${HOME}/.pyenv" ]; then
    export PYENV_ROOT="${HOME}/.pyenv"
elif [ -d /usr/local/opt/pyenv ]; then
    export PYENV_ROOT=/usr/local/opt/pyenv
fi

if [ -d "${PYENV_ROOT}" ]; then
    #pathprepend ${PYENV_ROOT}/bin
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi


if [ -f $HOME/.local/bin/virtualenvwrapper.sh ]; then
    . $HOME/.local/bin/virtualenvwrapper.sh
elif [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
fi

export PERLBREW_ROOT=$HOME/.perl5/perlbrew
if [ -f /usr/local/bin/perlbrew ]; then
    #export PERLBREW_ROOT=$HOME/.perl5/perlbrew
    # /usr/local/bin/perlbrew init
    source ~/.perl5/perlbrew/etc/bashrc
fi

if [ -f ~/.opam/opam-init/init.zsh ]; then
    # OPAM configuration
    . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
fi

if [ -f /usr/local/share/zsh/site-functions/_aws ]; then
    source /usr/local/share/zsh/site-functions/_aws
fi

# dircolors
if [ -f dircolors ]; then
    eval `dircolors ~/.dircolors-solarized/dircolors.256dark`
elif [ -f /opt/local/usr/bin/gdircolors ]; then  # macports gdircolors
    eval `gdircolors ~/.dircolors-solarized/dircolors.256dark`
fi

# python path for macports framework
if [ -d /opt/local/Library/Frameworks/Python.framework/Versions/Current/bin ]; then
    pathappend /opt/local/Library/Frameworks/Python.framework/Versions/Current/bin
fi


## postgres paths
if [ -d /opt/local/lib/postgresql93/bin ]; then  # macports
    pathappend /opt/local/lib/postgresql93/bin
fi

BASE16_SCHEME="monokai"
BASE16_SHELL="$HOME/.config/base16-shell/base16-$BASE16_SCHEME.dark.sh"
[[ -s $BASE16_SHELL ]] && . $BASE16_SHELL

source tmuxp.zsh

### Added by the Heroku Toolbelt
if [ -d /usr/local/heroku ]; then
    pathprepend /usr/local/heroku/bin
fi

if [ -d $HOME/.local/activator ]; then
    pathprepend $HOME/.local/activator
fi

if [ -d $HOME/.linuxbrew ]; then
    # Until LinuxBrew is fixed, the following is required.
    # See: https://github.com/Homebrew/linuxbrew/issues/47
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig:$PKG_CONFIG_PATH
    ## Setup linux brew
    export LINUXBREWHOME=$HOME/.linuxbrew
    pathprepend $LINUXBREWHOME/bin:$LINUXBREWHOME/sbin
    export MANPATH=$LINUXBREWHOME/man:$MANPATH
    export PKG_CONFIG_PATH=$LINUXBREWHOME/lib64/pkgconfig:$LINUXBREWHOME/lib/pkgconfig:$PKG_CONFIG_PATH
    export LD_LIBRARY_PATH=$LINUXBREWHOME/lib64:$LINUXBREWHOME/lib:$LD_LIBRARY_PATH
fi

if [ -d $HOME/.cabal ]; then
    pathprepend ~/.cabal/bin
fi

if [ -d $HOME/.composer/vendor/bin ]; then
    pathprepend ~/.composer/vendor/bin
fi

if [ -d $HOME/Library/Haskell ]; then
    pathprepend $HOME/Library/Haskell/bin
fi


[[ -s $HOME/.zshrc.local ]] && . $HOME/.zshrc.local
