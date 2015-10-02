# OSX
if [ -f ~/.profile ]; then
    . ~/.profile
fi

#[[ -s $HOME/.zshenv ]] && source $HOME/.zshenv

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

source $HOME/.dot-config/.shell/functions.sh

export EDITOR=vim

# thank you https://github.com/miohtama/ztanesh/blob/master/zsh-scripts/rc/01-detect-os
if [[ `uname` == 'Linux' ]]
then
    export LINUX=1
    export GNU_USERLAND=1
else
    export LINUX=
fi

if [[ `uname` == 'Darwin' ]]
then
    export OSX=1
else
    export OSX=
fi

export PYTHONSTARTUP=~/.pythonrc

if command -v cowsay >/dev/null 2>&1 && command -v fortune >/dev/null 2>&1; then
    fortune | cowsay -n
elif [ -f /usr/games/fortune ] && [ -f /usr/games/cowsay ]; then
    fortune | cowsay -n
fi

if command -v reattach-to-user-namespace > /dev/null; then
    alias vim="reattach-to-user-namespace vim"
    alias mvim="reattach-to-user-namespace mvim"
fi

alias battle.net="setarch i386 -L -B -R -3 taskset -c 2,3 /usr/share/playonlinux/playonlinux --run \"Battle.net\" %F"

# http://stackoverflow.com/a/12484846
export SBT_OPTS=-XX:MaxPermSize=1024m

function unix_ts { LBUFFER="${LBUFFER}$(date '+%Y%m%d%H%M%S')" }
zle -N unix_ts
bindkey "^t" unix_ts

# added by travis gem
[ -f /home/tony/.travis/travis.sh ] && source /home/tony/.travis/travis.sh
# keys for history-search-forward
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

[[ -s $HOME/.zshrc.local ]] && . $HOME/.zshrc.local
