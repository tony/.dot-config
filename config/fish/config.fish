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
