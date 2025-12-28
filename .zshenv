# .zshenv

##################################################
# Ubuntu-Specific Environment Variables
##################################################

# Skip the global compinit (on Ubuntu)
skip_global_compinit=1

# Skip the Ubuntu /etc/update-motd.d “message of the day”
export MOTD_SHOWN=1

##################################################
# Helper Functions
##################################################

# Safely source all readable *.sh files in a directory
source_all() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  for f in "$dir"/*.sh; do
    [[ -r "$f" ]] && source "$f"
  done
}

# Prepend one or more directories to PATH if they exist and are not already in PATH
pathprepend() {
  local d
  for d in "$@"; do
    if [[ -d "$d" && ":$PATH:" != *":$d:"* ]]; then
      PATH="$d${PATH:+":$PATH"}"
    fi
  done
}

##################################################
# Source /etc/profile.d/ scripts (if present)
##################################################

if [[ -d /etc/profile.d ]]; then
  source_all "/etc/profile.d"
fi

##################################################
# Source user-specific functions under ~/.dot-config/.shell/fn.sh
##################################################

if [[ -f "$HOME/.dot-config/.shell/fn.sh" ]]; then
  source "$HOME/.dot-config/.shell/fn.sh"
fi

##################################################
# Source user-specific scripts under ~/.dot-config/.shell/fn.d/
##################################################

if [[ -d "$HOME/.dot-config/.shell/fn.d" ]]; then

  # Then load the rest (excluding ignore.sh if you don’t want it re-sourced)
  for f in "$HOME/.dot-config/.shell/fn.d"/*.zsh; do
    [[ -r "$f" ]] && source "$f"
  done

fi

##################################################
# Source user-specific scripts under ~/.dot-config/.shell/vars.d/
##################################################

if [[ -d "$HOME/.dot-config/.shell/vars.d" ]]; then

  # If you specifically need to load ignore.sh first:
  if [[ -r "$HOME/.dot-config/.shell/vars.d/ignore.sh" ]]; then
    source "$HOME/.dot-config/.shell/vars.d/ignore.sh"
  fi

  # Then load the rest (excluding ignore.sh if you don’t want it re-sourced)
  for f in "$HOME/.dot-config/.shell/vars.d"/*.sh; do
    [[ "$f" == *ignore.sh ]] && continue
    [[ -r "$f" ]] && source "$f"
  done

fi

##################################################
# Ensure XDG_CONFIG_HOME is defined
##################################################

# If XDG_CONFIG_HOME is not set, default to ~/.config
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

##################################################
# Mise Performance Optimization (port from fish config)
##################################################

# Only run mise hook-env on directory change, not every prompt
export MISE_HOOK_ENV_CHPWD_ONLY=true
# Cache filesystem stat checks for 5 seconds (helps on WSL2/NFS)
export MISE_HOOK_ENV_CACHE_TTL=5s

##################################################
# Other Environment Variables
##################################################

# MichaelAquilina/zsh-autoswitch-virtualenv
export AUTOSWITCH_SILENT=1

# Python custom REPL init
export PYTHONSTARTUP="$HOME/.pythonrc"

##################################################
# PATH Adjustments
##################################################

# Prepend personal bin directories
pathprepend "$HOME/bin" "$HOME/.local/bin"

# Yarn path handled by corepack (bundled with Node.js via mise)
# Removed yarn global bin check - it's an expensive subprocess call

##################################################
# Optional: Source Cargo if it exists
##################################################

if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi
