# OSX
if [ -f ~/.profile ]; then
    . ~/.profile
fi


# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="steeef"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
export DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git docker npm node brew pip python)

source $ZSH/oh-my-zsh.sh




export EDITOR=vim
# Customize to your needs...
export PATH=$HOME/.local/bin:./node_modules/.bin:$HOME/bin:/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PATH

fixssh() {
    for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
        if (tmux show-environment | grep "^${key}" > /dev/null); then
            value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
            export ${key}="${value}"
        fi
    done
}

export NODE_PATH=/usr/local/share/npm/lib/node_modules
export PATH=/usr/local/share/npm/bin:$PATH

# rbenv
if [ -f $HOME/.rbenv/bin ]; then
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
elif [ -f /usr/lib/rbenv/libexec/rbenv ]; then
    export PATH="/usr/lib/rbenv/libexec/:$PATH"
    eval "$(rbenv init -)"
fi

## pyenv paths
if [ -d "${HOME}/.pyenv" ]; then
    export PYENV_ROOT="${HOME}/.pyenv"
elif [ -d /usr/local/opt/pyenv ]; then
    export PYENV_ROOT=/usr/local/opt/pyenv
fi

if [ -d "${PYENV_ROOT}" ]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
    eval "$(pyenv init -)"
fi


if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
fi

export PERLBREW_ROOT=$HOME/.perl5/perlbrew
if [ -f /usr/local/bin/perlbrew ]; then
    #export PERLBREW_ROOT=$HOME/.perl5/perlbrew
    # /usr/local/bin/perlbrew init
    source ~/.perl5/perlbrew/etc/bashrc
fi

if [ -f /usr/games/fortune ] && [ -f /usr/games/cowsay ]; then
    fortune | cowsay -n
fi

if [ -f ~/.opam/opam-init/init.zsh ]; then
    # OPAM configuration
    . ~/.opam/opam-init/init.zsh > /dev/null 2> /dev/null || true
fi


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

# detect AWS Elastic Beanstalk Command Line Tool
# http://aws.amazon.com/code/6752709412171743
# if [ -d ~/.aws/eb ]; then
#     if [[ "$OSX" == "1" ]]; then
#         export PATH=$PATH:$HOME/.aws/eb/macosx/python2.7
#     fi
#
#     if [[ "$LINUX" == "1" ]]; then
#         export PATH=$PATH:~/.aws/eb/linux/python2.7
#     fi
# fi

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
    export PATH=$PATH:/opt/local/Library/Frameworks/Python.framework/Versions/Current/bin
fi


## postgres paths
if [ -d /opt/local/lib/postgresql93/bin ]; then  # macports
    export PATH=$PATH:/opt/local/lib/postgresql93/bin
fi



source tmuxp.zsh

export PYTHONSTARTUP=~/.pythonrc

# To enable shims and autocompletion add to your profile:
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

# To use Homebrew's directories rather than ~/.pyenv add to your profile:
# export PYENV_ROOT=/usr/local/opt/pyenv

BASE16_SCHEME="monokai"
BASE16_SHELL="$HOME/.config/base16-shell/base16-$BASE16_SCHEME.dark.sh"
[[ -s $BASE16_SHELL ]] && . $BASE16_SHELL

if command -v cowsay >/dev/null 2>&1 && command -v fortune >/dev/null 2>&1; then
    fortune | cowsay -n
fi

if command -v reattach-to-user-namespace > /dev/null; then
    alias vim="reattach-to-user-namespace vim"
    alias mvim="reattach-to-user-namespace mvim"
fi

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# http://stackoverflow.com/a/12484846
export SBT_OPTS=-XX:MaxPermSize=1024m

export PATH="$PATH:$HOME/.local/activator"

export PATH="$HOME/.linuxbrew/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.linuxbrew/lib:$LD_LIBRARY_PATH"

[[ -s $HOME/.zshrc.local ]] && . $HOME/.zshrc.local

function unix_ts { LBUFFER="${LBUFFER}$(date '+%Y%m%d%H%M%S')" }
zle -N unix_ts
bindkey "^t" unix_ts
