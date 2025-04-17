# .zshenv (Minimal for mise PATH)

# Helper Functions
pathprepend() {
  local d
  for d in "$@"; do
    if [[ -d "$d" && ":$PATH:" != *":$d:"* ]]; then
      PATH="$d${PATH:+":$PATH"}"
    fi
  done
}

# Ensure XDG_CONFIG_HOME is defined (potentially used by mise or other tools)
if [[ -z "$XDG_CONFIG_HOME" ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

# PATH Adjustments for mise binary location
pathprepend "$HOME/.local/bin" # Common install location

# Optional: Source Cargo if it exists (for mise installed via cargo)
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env" # Adds ~/.cargo/bin to PATH
fi

# mise activation should be in .zshrc, not here.
