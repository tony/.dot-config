source ~/.dot-config/antigen.zsh


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

# antigen
antigen use oh-my-zsh

antigen bundle history
antigen bundle git
antigen bundle ssh-agent

antigen bundle mafredri/zsh-async
antigen bundle sindresorhus/pure

antigen bundle chrissicool/zsh-256color

antigen bundle zsh-users/zsh-syntax-highlighting

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Disable hostname completion, because it's slow
zstyle ':completion:*' hosts off


if command -v reattach-to-user-namespace > /dev/null; then
  alias vim="reattach-to-user-namespace vim"
  alias nvim="reattach-to-user-namespace nvim"
fi

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf'

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

source ~/.dot-config/.shell/paths.d/python.sh

# Exclude file types that can't be open in vim (FZF_DEFAULT_IGNORE is used for fzf.vim)
export IGNORE_FILE_EXT=""
IGNORE_FILE_EXT+="gz\|tar\|rar\|zip\|7z"
IGNORE_FILE_EXT+="\|min.js\|min.map"
IGNORE_FILE_EXT+="\|pdf\|doc\|docx"
IGNORE_FILE_EXT+="\|gif\|jpeg\|jpg\|png\|svg"
IGNORE_FILE_EXT+="\|snap"
IGNORE_FILE_EXT+="\|TTF\|ttf\|otf\|eot\|woff\|woff2"
IGNORE_FILE_EXT+="\|mp3\|m4a\|ape\|ogg\|opus\|flac"
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
IGNORE_FILE_WILD+="\|site-packages\|egg-info"
IGNORE_FILE_WILD+="\|node-gyp\|node_modules\|bower_components"
IGNORE_FILE_WILD+="\|build\|webpack_bundles"
IGNORE_FILE_WILD+="\|json\/test\/data"  # sdl2-playproject
IGNORE_FILE_WILD+="\|drive_[a-z]\/"  # WINE (esp if created in lutris)

export FZF_CUSTOM_GREP_IGNORE="
  grep --ignore-case --invert-match -e '.*[.]\(\
    ${IGNORE_FILE_EXT} \
  \)' -e '.*\(${IGNORE_FILE_WILD}\).*'
"

export FZF_DEFAULT_COMMAND="
(git ls-files --recurse-submodules ||
    find . -path '*/\.*' -prune -o -type f -print -o -type l \
    \( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print | \
   sed s/^..// \
) | ${FZF_CUSTOM_GREP_IGNORE} 2> /dev/null
"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
[ -f ~/.profile ] && source ~/.profile
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
[ -f ~/.local/share/dephell/_dephell_zsh_autocomplete ] && source ~/.local/share/dephell/_dephell_zsh_autocomplete

antigen apply
