###############################################################################
# Environment Variables & Constants
###############################################################################

# mise
export MISE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
export MISE_DATA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
# Don't set this as a TOML config file
# export MISE_GLOBAL_CONFIG_FILE="${HOME}/.tool-versions"
export MISE_CARGO_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-cargo-crates"
export MISE_PYTHON_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-python-packages"
export MISE_NODE_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-npm-packages"
export MISE_ASDF_COMPAT=true

# Node.js
export COREPACK_ENABLE_STRICT=0  # Silence corepack warnings

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

# If in VSCode/Cursor terminal, use ultra-minimal config.
# This is detected by checking for environment variables set by VSCode/Cursor
# ($TERM_PROGRAM or $VSCODE_CWD).
# The goal is to provide a minimal, fast, and non-interactive environment
# for agent commands. This helps ensure that complex shell features (like
# custom prompts, plugins, hooks) don't interfere with the agent's ability
# to reliably run commands and detect their exit status or completion.
# See also: https://github.com/microsoft/vscode/tree/1.99.3/src/vs/workbench/contrib/terminal/common/scripts
if [[ "$TERM_PROGRAM" = "vscode" || -n "$VSCODE_CWD" ]]; then
  # Do NOT set PS1 here. While aiming for minimal, overriding PS1 can
  # interfere with VSCode's shell integration features, which rely on
  # manipulating the prompt or using precmd/preexec hooks.
  # Let VSCode's injected scripts handle the prompt.
  # export PS1="%~ $ "

  # Performance settings for non-interactive use
  export PAGER=cat
  export GIT_PAGER=cat
  export NO_COLOR=1
  export VITEST_REPORTER=dot

  # Disable history to improve performance and avoid conflicts
  HISTFILE=/dev/null

  # Only load core toolchain environment variables
  # Ensure essential tools managed by mise/asdf/cargo/rye are available.

  # mise (critical) - Let sheldon handle activation consistently
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
  fi

  # asdf (if mise doesn't cover it)
  if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
    source "$HOME/.asdf/asdf.sh"
  fi

  # Basic PATH additions for essential tools
  # Cargo
  if [[ -f "${HOME}/.cargo/env" ]]; then
    source "${HOME}/.cargo/env"
  fi

  # Rye (Python)
  if [[ -f "${HOME}/.rye/env" ]]; then
    source "${HOME}/.rye/env"
  fi

  # Exit early - skip everything else in .zshrc
  # This is the crucial step to prevent loading complex shell features below.
  return 0
fi

# Regular shell configuration continues below for non-VSCode sessions
# If ZDOTDIR isn't already set, default it to $HOME.
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
# VSCode/Cursor Configuration
###############################################################################

# Set pager configuration when in VSCode/Cursor
# if [[ "$TERM_PROGRAM" = "vscode" ]]; then
#   export PAGER=cat
#   export GIT_PAGER=cat
#   # Do not store history inside editors
#   setopt HIST_NO_STORE
#   fc -R ~/.zsh_history   # Reload your existing history into memory
#   HISTFILE=/dev/null
#   unset HISTFILE         # Disable further writes to the history file

#   # Forbid color in output for console / agent loops, e.g. in vitest
#   export NO_COLOR=1
# fi

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
alias git_restore_main='git restore --source=origin/main --staged --worktree .'
alias git_restore_master='git restore --source=origin/master --staged --worktree .'
alias git_branch_history_log='git log --patch --no-merges "$(
  REMOTE=$(git remote 2>/dev/null | head -n1); \
  git remote show "$REMOTE" 2>/dev/null | awk "/HEAD branch/ {print \"$REMOTE/\" \$NF}" \
    || { for b in main master; do \
           git show-ref --verify --quiet "refs/remotes/$REMOTE/$b" && \
           printf \\'%s/%s\\' "$REMOTE" "$b" && break; \
         done; } \
)"..HEAD'
alias git_branch_history_diff='git diff --patch "$(
  REMOTE=$(git remote 2>/dev/null | head -n1); \
  git remote show "$REMOTE" 2>/dev/null | awk "/HEAD branch/ {print \"$REMOTE/\" \$NF}" \
    || { for b in main master; do \
           git show-ref --verify --quiet "refs/remotes/$REMOTE/$b" && \
           printf \\'%s/%s\\' "$REMOTE" "$b" && break; \
         done; } \
)"..HEAD'

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

###############################################################################
# Completions
###############################################################################

# Ensure ~/.zfunc directory exists for custom completions
make_dir_if_missing "${HOME}/.zfunc"
fpath+="${HOME}/.zfunc"

# mise completions
if command -v mise >/dev/null 2>&1; then
  if [[ ! -f "${HOME}/.zfunc/_mise" ]]; then
    mise completions zsh > "${HOME}/.zfunc/_mise"
  fi
fi

# sheldon
if command -v sheldon >/dev/null 2>&1; then
  if [[ ! -f "${HOME}/.zfunc/_sheldon" ]]; then
    sheldon completions --shell zsh > "${HOME}/.zfunc/_shelldon"
  fi
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
