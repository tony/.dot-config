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
HISTFILE="${HOME}/.zsh_history"  # where to store zsh history
HISTSIZE=10000
SAVEHIST=10000

setopt append_history           # append to history file
setopt hist_expire_dups_first
setopt hist_ignore_all_dups     # remove all lines matching prev commands
setopt hist_ignore_space        # ignore commands starting with space
setopt hist_verify              # preview history command before running
setopt inc_append_history       # share commands across multiple terminals
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

# Simple benchmarking
alias bench='for i in $(seq 1 10); do /usr/bin/time /bin/zsh -i -c exit; done;'

###############################################################################
# Antidote (Plugin Manager)
###############################################################################
antidote_dir="${ZDOTDIR}/.antidote"
plugins_txt="${ZDOTDIR}/.zsh_plugins.txt"
static_file="${ZDOTDIR}/.zsh_plugins.zsh"

# Make plugin folder names more readable
zstyle ':antidote:bundle' use-friendly-names 'yes'

# Clone antidote if necessary, rebuild static plugin file if needed
if [[ ! -e "$static_file" || "$static_file" -ot "$plugins_txt" ]]; then
  [[ -d "$antidote_dir" ]] || git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
  (
    source "${antidote_dir}/antidote.zsh"
    [[ -e "$plugins_txt" ]] || touch "$plugins_txt"
    antidote bundle <"$plugins_txt" >"$static_file"
  )
fi

# Load antidote commands if desired (comment out if not needed)
autoload -Uz "${antidote_dir}/functions/antidote"

# Actually load the plugins
antidote load

# Optionally source the static plugin file directly
# source "$static_file"

###############################################################################
# Post-Plugin Install Actions
###############################################################################

# Starship logs: disable warnings
export STARSHIP_LOG=error

# HSTR (history search) config
if command -v hstr >/dev/null 2>&1; then
  alias hh='hstr'
  setopt histignorespace
  export HSTR_CONFIG='hicolor'
  bindkey -s '\C-r' '\C-a hstr -- \C-j'
  export HSTR_TIOCSTI='y'
fi

# Ensure fzf is installed if junegunn/fzf plugin is present via antidote
if [[ ! -e "$(antidote home)/junegunn/fzf/bin/fzf" && -d "$(antidote home)/junegunn/fzf" ]]; then
  antidote load
  "$(antidote home)/junegunn/fzf/install" --bin
fi

# fzf-zsh-plugin load fallback
if [[ ! -e "$(antidote home)/unixorn/fzf-zsh-plugin/fzf-zsh-plugin.zsh" ]]; then
  source_if_exists "$(antidote home)/unixorn/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh"
fi

# Starship installation check
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

# Initialize starship prompt
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
# Additional patterns to ignore
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