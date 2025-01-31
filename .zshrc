# If ZDOTDIR isn’t already set, default it to $HOME.
ZDOTDIR="${ZDOTDIR:-$HOME}"

###############################################################################
# Helper Functions
###############################################################################

# Safely source a file if it exists and is readable
source_if_exists() {
  local file="$1"
  [[ -r "$file" ]] && source "$file"
}

# Create a directory if it doesn't exist
make_dir_if_missing() {
  local dir="$1"
  [[ -d "$dir" ]] || mkdir -p "$dir"
}

###############################################################################
# Environment Variables & Constants
###############################################################################

# asdf
export ASDF_DATA_DIR="${XDG_CONFIG_HOME}/asdf"
export ASDF_CONFIG_FILE="${HOME}/.asdfrc"
export ASDF_CRATE_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-cargo-crates"
export ASDF_PYTHON_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-python-packages"
export ASDF_NPM_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-npm-packages"
export ASDF_POETRY_INSTALL_URL="https://install.python-poetry.org"
export ASDF_NODEJS_AUTO_ENABLE_COREPACK=1

# Cache fix
export ZSH_CACHE_DIR="${HOME}/.zsh"

# Disable usage telemetry
export SAM_CLI_TELEMETRY=0
export GATSBY_TELEMETRY_DISABLED=1
export NEXT_TELEMETRY_DISABLED=1  # Next.js

# Python
export PYTHONSTARTUP="${HOME}/.pythonrc"

# Editor
export EDITOR="vim"

# Terminal TTY reference
export TTY="$(tty)"

###############################################################################
# History Options
###############################################################################
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt append_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history

###############################################################################
# Keybindings & Vim-like Input
###############################################################################

# Emacs-style keybindings
bindkey -e

# Ctrl-x-e to edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

###############################################################################
# Aliases
###############################################################################
alias clear_pyc='find . -type f -regex ".*\(\.pyc\|\.pyo\|__pycache__\).*" -delete'
alias clear_empty_dirs='find . -type d -empty -delete'
alias clear_biome='rm -rf **/biome-socket-* **/biome-logs'
alias git_prune_local='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'
alias update_packages='pushd "${HOME}/.dot-config"; make global_update; popd;'
alias update_repos='pushd "${HOME}/.dot-config"; make vcspull; popd;'
alias bench='for i in $(seq 1 10); do /usr/bin/time /bin/zsh -i -c exit; done;'

###############################################################################
# Plugin Manager (Sheldon)
###############################################################################
# If you haven't already, create ~/.config/sheldon/plugins.toml with your plugins,
# then run `sheldon lock` to generate a static file. 
#
# By default, Sheldon writes the locked file to ~/.local/share/sheldon/plugins.zsh
# (You can customize that path with `sheldon lock --output <path>`).

if command -v sheldon >/dev/null 2>&1; then
  # Optionally auto-lock each time you start a shell (slower):
  # sheldon lock

  eval "$(sheldon source)"
fi

###############################################################################
# Post-Plugin Setup
###############################################################################

# Starship logs: disable warnings
export STARSHIP_LOG=error

# Check starship installation (optional convenience)
if ! command -v starship >/dev/null 2>&1; then
  echo "Starship not found, attempting download..."
  if command -v wget >/dev/null 2>&1; then
    wget https://starship.rs/install.sh -O install_starship.sh
  elif command -v curl >/dev/null 2>&1; then
    curl -sS -o install_starship.sh https://starship.rs/install.sh
  else
    echo "Cannot download starship; neither wget nor curl is installed."
    return 1
  fi
  sh ./install_starship.sh
  rm ./install_starship.sh
fi
eval "$(starship init zsh)"

###############################################################################
# Completions
###############################################################################

# Ensure ~/.zfunc directory exists for custom completions
make_dir_if_missing "${HOME}/.zfunc"
fpath+="${HOME}/.zfunc"

# asdf completions
if [[ -n "$ASDF_DIR" && -d "${ASDF_DIR}/completions" ]]; then
  fpath=("${ASDF_DIR}/completions" $fpath)
fi

# Poetry completions
if command -v poetry >/dev/null 2>&1; then
  if [[ ! -f "${HOME}/.zfunc/_poetry" ]]; then
    poetry completions zsh > "${HOME}/.zfunc/_poetry"
  fi
fi

# Rustup completions
if command -v rustup >/dev/null 2>&1; then
  if [[ ! -f "${HOME}/.zfunc/_rustup" ]]; then
    rustup completions zsh > "${HOME}/.zfunc/_rustup"
  fi
  if [[ ! -f "${HOME}/.zfunc/_cargo" ]]; then
    rustup completions zsh cargo > "${HOME}/.zfunc/_cargo"
  fi
fi

# Initialize zsh completions
autoload -Uz +X compinit
compinit

# Completion style settings
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR}/cache"
zstyle ':completion:*' hosts off
zstyle ':completion:*' ignored-patterns \
    '*?.aux' '*?.bbl' '*?.blg' '*?.out' '*?.log' '*?.toc' '*?.snm' '*?.nav' \
    '*?.pdf' '*?.bak' '*\~' '*?.dll'

###############################################################################
# AWS CLI v2 completions
###############################################################################

if command -v aws_completer >/dev/null 2>&1; then
  AWS_ZSH_COMPLETION_SCRIPT_PATH="${HOME}/.shell/completions/aws_zsh_completer.sh"
  source_if_exists "$AWS_ZSH_COMPLETION_SCRIPT_PATH"
fi

###############################################################################
# Terraform completions
###############################################################################

if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit
  bashcompinit
  complete -o nospace -C terraform terraform
fi

###############################################################################
# Yarn / Deno / Bob
###############################################################################

# Yarn
if [[ -d "${HOME}/.yarn/bin" ]]; then
  export PATH="${PATH}:${HOME}/.yarn/bin"
fi

# Deno
if [[ -d "${HOME}/.deno/bin" ]]; then
  export DENO_INSTALL="${HOME}/.deno"
  export PATH="${DENO_INSTALL}/bin:${PATH}"
fi

# Bob (Neovim version manager)
if [[ -d "${HOME}/.local/share/bob" ]]; then
  export BOB_NVIM_PATH="${HOME}/.local/share/bob/nvim-bin/"
  export PATH="${BOB_NVIM_PATH}:${PATH}"
fi

###############################################################################
# Additional Local Sourcing
###############################################################################

# Source an optional local config
source_if_exists "${HOME}/.zshrc.local"

# Cargo environment
source_if_exists "${HOME}/.cargo/env"

# Rye environment (Python)
source_if_exists "${HOME}/.rye/env"
