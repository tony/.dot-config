set -Ux EDITOR (which vim)
set -Ux VISUAL $EDITOR
set -Ux SUDO_EDITOR $EDITOR

# Disable fish greeting
set fish_greeting

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
    fzf_key_bindings

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

set fzf_fd_opts -xg "-path '*/\.*' -prune -o -type f -print -o -type l \
    \( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print"

if type -q fzf
    # Assume IGNORE_FILE_EXT is set by ./ignore.sh or some other mechanism in Fish

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
