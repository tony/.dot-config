### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit's installer chunk

# tmux / tmuxp
export DISABLE_AUTO_TITLE='true'

# https://github.com/robbyrussell/oh-my-zsh/issues/5874
export ZSH_CACHE_DIR=$HOME/.zsh

# For poetry: https://github.com/python-poetry/poetry#enable-tab-completion-for-bash-fish-or-zsh
fpath+=~/.zfunc

# additional completions
autoload -U +X compinit && compinit

# ignore hosts completion
zstyle ':completion:*' hosts off

##
## History
###
### Source: https://dustri.org/b/my-zsh-configuration.html
### Also https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/history.zsh
HISTFILE=~/.zsh_history         # where to store zsh config
HISTSIZE=10000                   # big history
SAVEHIST=10000                   # big history
setopt append_history           # append
setopt hist_expire_dups_first
setopt hist_ignore_all_dups     # no duplicate
setopt hist_ignore_space      # ignore space prefixed commands
setopt hist_verify              # show before executing history commands
setopt inc_append_history       # add commands as they are typed, don't wait until shell exit 
setopt share_history            # share hist between sessions

zinit snippet OMZ::plugins/history/history.plugin.zsh
zinit snippet OMZ::plugins/git/git.plugin.zsh
zinit snippet OMZ::plugins/ssh-agent/ssh-agent.plugin.zsh

# zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
# zinit light sindresorhus/pure
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

zinit load chrissicool/zsh-256color

zinit load zsh-users/zsh-syntax-highlighting

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Disable hostname completion, because it's slow
zstyle ':completion:*' hosts off


if command -v reattach-to-user-namespace > /dev/null; then
  alias vim="reattach-to-user-namespace vim"
  alias nvim="reattach-to-user-namespace nvim"
fi

# for OS X keychain(1) error, Error: Problem adding; giving up
# if ! fuser "$SSH_AUTH_SOCK" >/dev/null 2>/dev/null; then
#   # Nothing has the socket open, it means the agent isn't running
#   ssh-agent -a "$SSH_AUTH_SOCK" -s >~/.ssh/agent-info
# fi
fixssh() {
    for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
        if (tmux show-environment | grep "^${key}" > /dev/null); then
            value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
            export ${key}="${value}"
        fi
    done
}
fixssh()
source ~/.dot-config/.shell/env.d/most.sh
source ~/.dot-config/.shell/env.d/python-breakpoint.sh
source ~/.dot-config/.shell/aliases.sh

pathprepend() {
  for ARG in "$@"
  do
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

source ~/.dot-config/.shell/paths.d/yarn.sh
source ~/.dot-config/.shell/env.d/pyenv.sh
if [ ! -d "$HOME/.pyenv" ]; then
    source ~/.dot-config/.shell/paths.d/python.sh
fi
source ~/.dot-config/.shell/env.d/poetry.sh

# source ~/.dot-config/.shell/env.d/nvm.sh
export NVM_LAZY_LOAD=true
zplugin ice wait"1" lucid
zplugin light lukechilds/zsh-nvm

# Exclude file types that can't be open in vim (FZF_DEFAULT_IGNORE is used for fzf.vim)
export IGNORE_FILE_EXT=""
IGNORE_FILE_EXT+="gz\|tar\|rar\|zip\|7z"
IGNORE_FILE_EXT+="\|min.js\|min.map"
IGNORE_FILE_EXT+="\|pdf\|doc\|docx"
IGNORE_FILE_EXT+="\|ppt\|pptx"
IGNORE_FILE_EXT+="\|gif\|jpeg\|jpg\|png\|svg"
IGNORE_FILE_EXT+="\|psd\|xcf"
IGNORE_FILE_EXT+="\|ai\|epub\|kpf\|mobi"
IGNORE_FILE_EXT+="\|snap"
IGNORE_FILE_EXT+="\|TTF\|ttf\|otf\|eot\|woff\|woff2"
IGNORE_FILE_EXT+="\|wma\|mp3\|m4a\|ape\|ogg\|opus\|flac"
IGNORE_FILE_EXT+="\|mp4\|wmv\|avi\|mkv\|webm\|m4b"
IGNORE_FILE_EXT+="\|musicdb\|itdb\|itl\|itc"
IGNORE_FILE_EXT+="\|o\|so\|dll"
IGNORE_FILE_EXT+="\|cbor\|msgpack"
IGNORE_FILE_EXT+="\|wpj"

export IGNORE_FILE_WILD=""
IGNORE_FILE_WILD+="cache"
IGNORE_FILE_WILD+="\|Library\|Cache"  # mac
IGNORE_FILE_WILD+="\|AppData"  # Windows
IGNORE_FILE_WILD+="\|Android"
IGNORE_FILE_WILD+="\|site-packages\|egg-info\|dist-info"
IGNORE_FILE_WILD+="\|node-gyp\|node_modules\|bower_components"
IGNORE_FILE_WILD+="\|build\|webpack_bundles"
IGNORE_FILE_WILD+="\|json\/test\/data"  # sdl2-playproject
IGNORE_FILE_WILD+="\|drive_[a-z]\/"  # WINE (esp if created in lutris)
IGNORE_FILE_WILD+="\|\^\?\(\.\/\)snap\/"  # $HOME/snap/ (when FZF invoked via home directory)
IGNORE_FILE_WILD+="\|^snap\/"  # $HOME/snap/ (when FZF invoked via home directory)
IGNORE_FILE_WILD+="\|\/gems\/"  # canvas-lms
IGNORE_FILE_WILD+="\|^work\/\|^study\/"  # canvas-lms

export FZF_CUSTOM_GREP_IGNORE="
  grep --ignore-case --invert-match -e '.*[.]\(\
    ${IGNORE_FILE_EXT} \
  \)' -e '.*\(${IGNORE_FILE_WILD}\).*'
"

export FZF_FIND_COMMAND="find . -path '*/\.*' -prune -o -type f -print -o -type l \
\( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print"

export FZF_DEFAULT_COMMAND="(git ls-files --recurse-submodules & git ls-files --exclude-standard --others ||
    ${FZF_FIND_COMMAND} | \
   sed s/^..// \
) | ${FZF_CUSTOM_GREP_IGNORE} 2> /dev/null"

export FZF_CTRL_T_COMMAND="$FZF_FIND_COMMAND | ${FZF_CUSTOM_GREP_IGNORE} 2> /dev/null"

# Binary release in archive, from GitHub-releases page.
# After automatic unpacking it provides program "fzf".
zinit ice from"gh-r" as"program"
zinit load junegunn/fzf-bin
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
[ -f ~/.profile ] && source ~/.profile
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f ~/.local/share/dephell/_dephell_zsh_autocomplete ] && source ~/.local/share/dephell/_dephell_zsh_autocomplete

export DOCKER_HOST=unix:///run/user/1000/docker.sock

pathprepend $HOME/bin
