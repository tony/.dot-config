#!/bin/zsh

typeset -U PATH # remove duplicate entries

autoload -U +X compinit && compinit

source $HOME/.dot-config/.shell/aliases.sh
source $HOME/.dot-config/.shell/functions.sh


source $HOME/.dot-config/.shell/env.d/npm.sh
source $HOME/.dot-config/.shell/env.d/rbenv.sh
source $HOME/.dot-config/.shell/env.d/pyenv.sh
source $HOME/.dot-config/.shell/env.d/virtualenvwrapper.sh
source $HOME/.dot-config/.shell/env.d/perlbrew.sh
source $HOME/.dot-config/.shell/env.d/opam.sh
source $HOME/.dot-config/.shell/env.d/aws.sh
source $HOME/.dot-config/.shell/env.d/dircolors.sh
source $HOME/.dot-config/.shell/env.d/macports_python.sh
source $HOME/.dot-config/.shell/env.d/base16-shell.sh
source $HOME/.dot-config/.shell/env.d/postgres.sh
source $HOME/.dot-config/.shell/env.d/heroku.sh
source $HOME/.dot-config/.shell/env.d/activator.sh
source $HOME/.dot-config/.shell/env.d/linuxbrew.sh
source $HOME/.dot-config/.shell/env.d/cabal.sh
source $HOME/.dot-config/.shell/env.d/composer.sh
source $HOME/.dot-config/.shell/env.d/haskell.sh
source $HOME/.dot-config/.shell/env.d/lightdm.sh
source $HOME/.dot-config/.shell/env.d/oh-my-zsh.zsh
source $HOME/.dot-config/.shell/env.d/tmuxp.sh

source $HOME/.dot-config/.shell/paths.d/golang.sh

# Customize to your needs...
pathprepend $HOME/.local/bin $HOME/bin 
pathprepend /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin 
pathprepend /usr/games /usr/local/games
