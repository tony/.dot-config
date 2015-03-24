#!/bin/zsh

autoload -U +X compinit && compinit

source $HOME/.dot-config/.shell/aliases.sh
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
source $HOME/.dot-config/.shell/env/postgres.sh
source $HOME/.dot-config/.shell/env/heroku.sh
source $HOME/.dot-config/.shell/env/activator.sh
source $HOME/.dot-config/.shell/env/linuxbrew.sh
source $HOME/.dot-config/.shell/env/cabal.sh
source $HOME/.dot-config/.shell/env/composer.sh
source $HOME/.dot-config/.shell/env/haskell.sh
source $HOME/.dot-config/.shell/env/lightdm.sh
# source $HOME/.dot-config/.shell/env/oh-my-zsh.zsh
source $HOME/.dot-config/.shell/env/prezto.zsh


# Customize to your needs...
pathprepend $HOME/.local/bin $HOME/bin 
pathprepend /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin 
pathprepend /usr/games /usr/local/games

# Ensure that a non-login, non-interactive shell has a defined environment.
# from sorin/ionescu/prezto
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

[[ -s $HOME/.zshrc.local ]] && . $HOME/.zshrc.local


