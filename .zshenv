#!/bin/zsh

source $HOME/.dot-config/.shell/functions.sh
source $HOME/.dot-config/.shell/env/npm.sh
source $HOME/.dot-config/.shell/env/rbenv.sh
source $HOME/.dot-config/.shell/env/pyenv.sh
source $HOME/.dot-config/.shell/env/virtualenvwrapper.sh
source $HOME/.dot-config/.shell/env/perlbrew.sh
source $HOME/.dot-config/.shell/env/opam.sh
source $HOME/.dot-config/.shell/env/aws.sh
source $HOME/.dot-config/.shell/env/dircolors.sh
source $HOME/.dot-config/.shell/env/macports_python.sh
source $HOME/.dot-config/.shell/env/base16-shell.sh
source $HOME/.dot-config/.shell/env/tmuxp.sh

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

ZSH_THEME="steeef"

export DISABLE_AUTO_TITLE="true"

plugins=(git docker npm node brew brew-cask pip python)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
# export PATH=$HOME/.local/bin:./node_modules/.bin:$HOME/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PATH
pathprepend $HOME/.local/bin  $HOME/bin /usr/lib/lightdm/lightdm /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/games /usr/local/games $PATH

## postgres paths
if [ -d /opt/local/lib/postgresql93/bin ]; then  # macports
    pathappend /opt/local/lib/postgresql93/bin
fi




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
