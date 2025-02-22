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

# asdf configuration
set -Ux ASDF_DATA_DIR "$XDG_CONFIG_HOME/asdf"
set -Ux ASDF_CONFIG_FILE "$HOME/.asdfrc"
set -Ux ASDF_CRATE_DEFAULT_PACKAGES_FILE "$HOME/.default-cargo-crates"
set -Ux ASDF_PYTHON_DEFAULT_PACKAGES_FILE "$HOME/.default-python-packages"
set -Ux ASDF_NPM_DEFAULT_PACKAGES_FILE "$HOME/.default-npm-packages"
set -Ux ASDF_POETRY_INSTALL_URL "https://install.python-poetry.org"

# Node.js
set -Ux COREPACK_ENABLE_STRICT 0

# Disable telemetry
set -Ux SAM_CLI_TELEMETRY 0
set -Ux GATSBY_TELEMETRY_DISABLED 1
set -Ux NEXT_TELEMETRY_DISABLED 1

# Python
set -Ux PYTHONSTARTUP "$HOME/.pythonrc"

# Terminal TTY reference
set -Ux TTY (tty)

if test -d $ASDF_DIR
    if ! test ~/.config/fish/completions/asdf.fish
        mkdir -p ~/.config/fish/completions; and ln -s $ASDF_DIR/completions/asdf.fish ~/.config/fish/completions
    end
    source $ASDF_DIR/asdf.fish
else
    git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.0
end

if ! type -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
end

if type -q yarn
    set -U fish_user_paths (yarn global bin) $fish_user_paths
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

if type -q fzf
    set fzf_fd_opts -xg "-path '*/\.*' -prune -o -type f -print -o -type l \
		\( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print"

    # Check if IGNORE_FILE_EXT is set or empty
    if test -z "$IGNORE_FILE_EXT"
        # No ignores set

        set -x FZF_FIND_COMMAND "find . -path '*/\.*' -prune -o -type f -print -o -type l -print"

        set -x FZF_DEFAULT_COMMAND "(git ls-files --recurse-submodules & git ls-files --exclude-standard --others ||
		$FZF_FIND_COMMAND | \
			sed s/^..// \
			) 2> /dev/null"

        set -x FZF_DEFAULT_COMMAND "(git ls-files --recurse-submodules ||
		find . -path '*/\.*' -prune -o -type f -print -o -type l -print |
		sed s/^..//) 2> /dev/null"

    else
        # Exists
        set -xg FZF_CUSTOM_GREP_IGNORE "grep --ignore-case --invert-match -e '.*[.]\(\
			$IGNORE_FILE_EXT \
			\)' -e '.*\($IGNORE_FILE_WILD\).*'
		"

        set -xg FZF_FIND_COMMAND "find . -path '*/\.*' -prune -o -type f -print -o -type l \
			\( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print"

        function fzf_git_files
            set -l IFS
            # Capture the output of the git commands or FZF_FIND_COMMAND into a variable
            set command_output (git ls-files --recurse-submodules; or git ls-files --exclude-standard --others; or eval $FZF_FIND_COMMAND)

            # Process the captured output through sed and your custom grep ignore command
            echo $command_output | sed 's/^\.\.//' | eval $FZF_CUSTOM_GREP_IGNORE 2>/dev/null
        end

        set -xg FZF_DEFAULT_COMMAND fzf_git_files

        set -xg FZF_CTRL_T_COMMAND "$FZF_FIND_COMMAND | $FZF_CUSTOM_GREP_IGNORE 2> /dev/null"
    end
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
