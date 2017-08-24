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

source ~/.dot-config/.shell/env.d/base16-shell.sh
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
