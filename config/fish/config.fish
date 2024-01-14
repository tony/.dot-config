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
