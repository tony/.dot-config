# Set XDG paths if not already set
set -q XDG_CONFIG_HOME; or set -Ux XDG_CONFIG_HOME $HOME/.config
set -q XDG_CACHE_HOME; or set -Ux XDG_CACHE_HOME $HOME/.cache
set -q XDG_DATA_HOME; or set -Ux XDG_DATA_HOME $HOME/.local/share

# Set EDITOR environment variables
if type -q vim
    set -Ux EDITOR (type -p vim)
    set -Ux VISUAL $EDITOR
    set -Ux SUDO_EDITOR $EDITOR
end

# Disable fish greeting
set -g fish_greeting ''

# mise configuration
set -Ux MISE_CONFIG_DIR "$XDG_CONFIG_HOME/mise"
set -Ux MISE_DATA_DIR "$XDG_CONFIG_HOME/mise"
# Don't set this as a TOML config file
# set -Ux MISE_GLOBAL_CONFIG_FILE "$HOME/.tool-versions"
set -Ux MISE_CARGO_DEFAULT_PACKAGES_FILE "$HOME/.default-cargo-crates"
set -Ux MISE_PYTHON_DEFAULT_PACKAGES_FILE "$HOME/.default-python-packages"
set -Ux MISE_NODE_DEFAULT_PACKAGES_FILE "$HOME/.default-npm-packages"
set -Ux MISE_ASDF_COMPAT true

# Node.js
set -Ux COREPACK_ENABLE_STRICT 0

# Disable telemetry
set -Ux SAM_CLI_TELEMETRY 0
set -Ux GATSBY_TELEMETRY_DISABLED 1
set -Ux NEXT_TELEMETRY_DISABLED 1
set -Ux DISABLE_TELEMETRY 1

# Python
set -Ux PYTHONSTARTUP "$HOME/.pythonrc"

# Initialize mise if it exists, otherwise install it
if command -sq mise
    # mise already initialized in conf.d/mise.fish
else if not set -q FISH_TEST
    # Don't attempt to install mise during tests
    if command -sq curl
        curl -fsSL https://mise.run | sh
        fish_add_path ~/.local/bin
    end
end

if not set -q FISH_TEST
    if not type -q fisher
        curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
    end
end

if type -q yarn
    set -U fish_user_paths (yarn global bin) $fish_user_paths
end

# VSCode/Cursor Configuration
if test "$TERM_PROGRAM" = "vscode"; or set -q VSCODE_CWD
    set -gx PAGER cat
    set -gx GIT_PAGER cat
    # Do not store history inside editors
    set -gx fish_private_mode 1
end

if status is-interactive
    # Commands to run in interactive sessions can go here
    set -lx SHELL fish
    keychain --eval --agents ssh --quiet -Q id_ed25519 --nogui | source
end

function fish_user_key_bindings
    # Execute this once per mode that emacs bindings should be used in
    fish_default_key_bindings -M insert

    # Then execute the vi-bindings so they take precedence when there's a conflict.
    # Without --no-erase fish_vi_key_bindings will default to
    # resetting all bindings.
    # The argument specifies the initial mode (insert, "default" or visual).
    fish_vi_key_bindings --no-erase insert
end

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"

function fish_user_key_bindings
    if type -q fzf_key_bindings
        fzf_key_bindings
    end

    bind --user \cx \ce edit_command_buffer
    bind --user -M insert \cx\ce edit_command_buffer
    bind --user -M visual \cx\ce edit_command_buffer
end

function ignore_variables
    # Set IGNORE_FILE_EXT as a multi-line variable
    set IGNORE_FILE_EXT "gz|tar|rar|zip|7z" \
        "|min.js|min.map" \
        "|pdf|doc|docx" \
        "|ppt|pptx" \
        "|gif|jpeg|jpg|png|svg" \
        "|psd|xcf" \
        "|ai|epub|kpf|mobi" \
        "|snap" \
        "|TTF|ttf|otf|eot|woff|woff2" \
        "|wma|mp3|m4a|ape|ogg|opus|flac" \
        "|mp4|wmv|avi|mkv|webm|m4b" \
        "|musicdb|itdb|itl|itc" \
        "|o|so|dll" \
        "|cbor|msgpack" \
        "|wpj" \
        "|pyc" \
        "|js.map"

    # Set IGNORE_FILE_WILD as a multi-line variable
    set IGNORE_FILE_WILD "^snap/" \
        "|^cache|^_cache" \
        "|Library|^Cache" \
        "|AppData" \
        "|Android" \
        "|site-packages|egg-info|dist-info" \
        "|node-gyp|node_modules|bower_components" \
        "|^build|webpack_bundles" \
        "|json/test/data" \
        "|drive_[a-z]/" \
        "|^?(/)snap/" \
        "|^snap/" \
        "|/gems/" \
        "|^work/^study/" \
        "|__pycache__/" \
        "|^.cache/" \
        "|(_)?build/" \
        "|__generated__/"

    # Exporting the variables to make them available to child processes
    set -xg IGNORE_FILE_EXT $IGNORE_FILE_EXT
    set -xg IGNORE_FILE_WILD $IGNORE_FILE_WILD
end

ignore_variables

if type -q starship
    starship init fish | source
end

# History Configuration
set -g fish_history fish
set -Ux HISTFILE "$HOME/.local/share/fish/fish_history"
set -Ux HISTSIZE 10000
set -Ux SAVEHIST 10000

# Aliases
if status is-interactive
    # Clear commands
    alias clear_pyc='find . -type f -regex ".*\(\.pyc\|\.pyo\|__pycache__\).*" -delete'
    alias clear_empty_dirs='find . -type d -empty -delete'
    alias clear_biome='rm -rf **/biome-socket-* **/biome-logs'

    # Git commands
    alias git_prune_local='git branch --merged | egrep -v "(^\*|master|main|dev)" | xargs git branch -d'
    alias git_restore_main='git restore --source=origin/main --staged --worktree .'
    alias git_restore_master='git restore --source=origin/master --staged --worktree .'

    # Update commands
    alias update_packages='pushd "$HOME/.dot-config"; and make global_update; and popd'
    alias update_repos='pushd "$HOME/.dot-config"; and make vcspull; and popd'
end

# Skip fzf setup in test mode
if not set -q FISH_TEST
    # Pin fzf version
    set -gx FZF_VERSION "v0.60.2"

    # Ensure fzf is installed with the correct version
    if not command -q fzf; or test "$FZF_AUTO_UPDATE" = "true"
        fzf_mgr_ensure
    end
end
