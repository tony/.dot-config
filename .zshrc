
#
# Constants
#
export ASDF_DATA_DIR="$XDG_CONFIG_HOME/asdf"
export ASDF_CONFIG_FILE="$HOME/.asdfrc"
export ASDF_CRATE_DEFAULT_PACKAGES_FILE="$ZDOTDIR/.default-cargo-crates"
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE="$ZDOTDIR/.default-python-packages"
export ASDF_NPM_DEFAULT_PACKAGES_FILE="$ZDOTDIR/.default-npm-packages"
export ASDF_POETRY_INSTALL_URL="https://install.python-poetry.org"
export ASDF_NODEJS_AUTO_ENABLE_COREPACK=1

# Cache fix: https://github.com/robbyrussell/oh-my-zsh/issues/5874
export ZSH_CACHE_DIR=$HOME/.zsh

# Opt-out of spyware / spam
export SAM_CLI_TELEMETRY=0
export GATSBY_TELEMETRY_DISABLED=1

# Python
export PYTHONSTARTUP=$HOME/.pythonrc

#
# History
#
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

#
# vim-like input (for those big commands)
#

# Edit command in EDITOR with ctrl-x ctrl-x
export EDITOR=vim

# Assure emacs style Ctrl+A, Ctrl+D work with EDITOR declared
bindkey -e

# Enable Ctrl-x-e to edit command line
autoload -U edit-command-line
# Emacs style launch of EDITOR
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

#
# Aliases
#

alias clear_pyc='find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf'
alias clear_empty_dirs='find . -type d -empty -delete'
alias clear_biome='rm -rf **/biome-socket-*; rm -rf **/biome-logs'

alias git_prune_local='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'

alias update_packages='pushd ~/.dot-config; make global_update; popd;'
alias update_repos='pushd ~/.dot-config; make vcspull; popd;'

export TTY=$(tty)

alias bench='for i in $(seq 1 10); do /usr/bin//time /bin/zsh -i -c exit; done;'

#
# <Antidote> Plugins
#

# You can change the names/locations of these if you prefer.
antidote_dir=${ZDOTDIR:-~}/.antidote
plugins_txt=${ZDOTDIR:-~}/.zsh_plugins.txt
static_file=${ZDOTDIR:-~}/.zsh_plugins.zsh

# Make plugin folder names pretty
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Clone antidote if necessary and generate a static plugin file.
if [[ ! $static_file -nt $plugins_txt ]]; then
  [[ -e $antidote_dir ]] ||
    git clone --depth=1 https://github.com/mattmc3/antidote.git $antidote_dir
  (
    source $antidote_dir/antidote.zsh
    [[ -e $plugins_txt ]] || touch $plugins_txt
    antidote bundle <$plugins_txt >$static_file
  )
fi

# Uncomment this if you want antidote commands like `antidote update` available
# in your interactive shell session:
autoload -Uz $antidote_dir/functions/antidote

antidote load

# source the static plugins file
# source $static_file

# cleanup
# unset antidote_dir plugins_txt static_file

#
# </Antidote> Plugins
#

#
# <Antidote> Plugins: Post installation
#
# Install starship prompt
# Install fzf binary if not found

# Starship: Disable warnings (e.g. command_timeout)
export STARSHIP_LOG=error

if command -v hstr &> /dev/null; then
  # via hstr --show-zsh-configuration >> ~/.zshrc:
  # HSTR configuration - add this to ~/.zshrc
  alias hh=hstr                    # hh to be alias for hstr
  setopt histignorespace           # skip cmds w/ leading space from history
  export HSTR_CONFIG=hicolor       # get more colors
  bindkey -s "\C-r" "\C-a hstr -- \C-j"     # bind hstr to Ctrl-r (for Vi mode check doc)
  export HSTR_TIOCSTI=y
fi

if ! [[ -e "$(antidote home)/junegunn/fzf/bin/fzf" ]]
then
  antidote load
  "$(antidote home)/junegunn/fzf/install" --bin
fi

if ! command -v starship >/dev/null 2>&1; then
  if which wget >/dev/null ; then
    echo "Downloading via wget"
    wget https://starship.rs/install.sh
  elif which curl >/dev/null ; then
    echo "Downloading via curl"
    curl -sS -O https://starship.rs/install.sh
  else
    echo "Cannot download, neither wget nor curl. Exiting"
    exit 1
  fi
  sh ./install.sh
  rm ./install.sh
fi

# Load starship prompt
eval "$(starship init zsh)"

#
# Completions
# 

# Ensure zfunc directory exists
if [[ ! -d ~/.zfunc ]]; then
  mkdir ~/.zfunc
fi

# poetry: https://github.com/python-poetry/poetry#enable-tab-completion-for-bash-fish-or-zsh
fpath+=~/.zfunc

# asdf completions
if [[ -d $ASDF_DIR/completions ]]; then
  fpath=(${ASDF_DIR}/completions $fpath)
fi

# poetry
if command -v poetry &> /dev/null; then
  if [[ ! -f ~/.zfunc/_poetry ]]; then
    poetry completions zsh > ~/.zfunc/_poetry
  fi
fi

# rustup
if command -v rustup &> /dev/null; then
  if [[ ! -f ~/.zfunc/_rustup ]]; then
    rustup completions zsh > ~/.zfunc/_rustup
  fi
  if [[ ! -f ~/.zfunc/_cargo ]]; then
    rustup completions zsh cargo > ~/.zfunc/_cargo
  fi
fi

# Additional completions
autoload -Uz +X compinit && compinit

# Ignore hosts completion
zstyle ':completion:*' hosts off

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Disable hostname completion, because it's slow
zstyle ':completion:*' hosts off
# Ignore DLL's on WSL2, these make it slower to complete t<tab>
zstyle ':completion:*' ignored-patterns '*?.aux' '*?.bbl' '*?.blg' '*?.out' '*?.log' '*?.toc' '*?.snm' '*?.nav' '*?.pdf' '*?.bak' '*\~' '*?.dll'


if [[ -f ~/.shell/fn.sh ]] then
    source ~/.shell/fn.sh
fi

# AWS CLI v2 completions
if command -v aws_completer &> /dev/null; then
  AWS_ZSH_COMPLETION_SCRIPT_PATH=~/.shell/completions/aws_zsh_completer.sh
  if [[ -r $AWS_ZSH_COMPLETION_SCRIPT_PATH ]]; then
    [[ -r $AWS_ZSH_COMPLETION_SCRIPT_PATH ]] && source $AWS_ZSH_COMPLETION_SCRIPT_PATH
  fi
fi

if command -v terraform &> /dev/null; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C terraform terraform
fi

if [[ -d ~/.yarn/bin ]] then
  export PATH=$PATH:~/.yarn/bin
fi

if [[ -d ~/.deno/bin ]] then
  export DENO_INSTALL="$HOME/.deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

if [[ -d ~/.local/share/bob ]] then
  export BOB_NVIM_PATH=$HOME/.local/share/bob/nvim-bin/
  export PATH="$BOB_NVIM_PATH:$PATH"
fi

if [[ -f ~/.zshrc.local ]] then
  source ~/.zshrc.local
fi

if [[ -f "$HOME/.cargo/env" ]] then
  . "$HOME/.cargo/env"
fi

if [[ -f "$HOME/.rye/env" ]] then
  . "$HOME/.rye/env"
fi

# Disable Next.js telemetry
# Learn more here: https://nextjs.org/telemetry
export NEXT_TELEMETRY_DISABLED=1
