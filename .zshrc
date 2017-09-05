source ~/.dot-config/antigen.zsh

export DISABLE_AUTO_TITLE='true'

antigen use oh-my-zsh

antigen bundle history
antigen bundle git
antigen bundle npm
antigen bundle pip

antigen bundle zsh-users/zsh-completions src

antigen bundle mafredri/zsh-async
antigen bundle sindresorhus/pure

antigen bundle chriskempson/base16-shell
antigen bundle chriskempson/base16-iterm2

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

source ~/.dot-config/.shell/env.d/base16-shell.sh
# for OS X keychain(1) error, Error: Problem adding; giving up
fixssh() {
    for key in SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT; do
        if (tmux show-environment | grep "^${key}" > /dev/null); then
            value=`tmux show-environment | grep "^${key}" | sed -e "s/^[A-Z_]*=//"`
            export ${key}="${value}"
        fi
    done
}
fixssh()
source ~/.dot-config/.shell/env.d/keychain.sh
source ~/.dot-config/.shell/env.d/most.sh
pathprepend() {
  for ARG in "$@"
  do
    if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
        PATH="$ARG${PATH:+":$PATH"}"
    fi
  done
}

source ~/.dot-config/.shell/paths.d/python.sh
