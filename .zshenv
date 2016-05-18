#!/bin/zsh

if echo "$-" | grep i > /dev/null; then
    typeset -U PATH # remove duplicate entries

    autoload -U +X compinit && compinit

    source $HOME/.dot-config/.shell/functions.sh

    pathprepend /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
    pathprepend /usr/games /usr/local/games

    source $HOME/.dot-config/.shell/aliases.sh

    source $HOME/.dot-config/.shell/paths.d/python.sh

    source $HOME/.dot-config/.shell/env.d/p4a.sh
    source $HOME/.dot-config/.shell/env.d/opam.sh
    source $HOME/.dot-config/.shell/env.d/rbenv.sh
    source $HOME/.dot-config/.shell/env.d/pyenv.sh
    source $HOME/.dot-config/.shell/env.d/virtualenvwrapper.sh
    source $HOME/.dot-config/.shell/env.d/perlbrew.sh
    source $HOME/.dot-config/.shell/env.d/dircolors.sh
    source $HOME/.dot-config/.shell/env.d/base16-shell.sh
    source $HOME/.dot-config/.shell/env.d/oh-my-zsh.zsh
    source $HOME/.dot-config/.shell/env.d/tmuxp.sh
    source $HOME/.dot-config/.shell/env.d/keychain.sh
    source $HOME/.dot-config/.shell/env.d/most.sh

    source $HOME/.dot-config/.shell/paths.d/postgres_app.sh
    source $HOME/.dot-config/.shell/paths.d/brew_python.sh
    source $HOME/.dot-config/.shell/paths.d/macports_python.sh
    source $HOME/.dot-config/.shell/paths.d/opam.sh
    source $HOME/.dot-config/.shell/paths.d/aws.sh
    source $HOME/.dot-config/.shell/paths.d/postgres.sh
    source $HOME/.dot-config/.shell/paths.d/heroku.sh
    source $HOME/.dot-config/.shell/paths.d/activator.sh
    source $HOME/.dot-config/.shell/paths.d/linuxbrew.sh
    source $HOME/.dot-config/.shell/paths.d/cabal.sh
    source $HOME/.dot-config/.shell/paths.d/composer.sh
    source $HOME/.dot-config/.shell/paths.d/haskell.sh
    source $HOME/.dot-config/.shell/paths.d/lightdm.sh
    source $HOME/.dot-config/.shell/paths.d/npm.sh
    source $HOME/.dot-config/.shell/paths.d/golang.sh
    source $HOME/.dot-config/.shell/paths.d/rust.sh

    # Customize to your needs...
    pathprepend $HOME/.local/bin $HOME/bin

    # Add completions to path
    fpath+="$HOME/.dot-config/.shell/completions.d"
    autoload -U compinit && compinit
fi
