if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -d "$HOME/.zinit/plugins/asdf"
  source ~/.zinit/plugins/asdf/asdf.fish
end


if status is-interactive
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
