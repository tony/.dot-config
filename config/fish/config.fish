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
