if status is-interactive
    # Commands to run in interactive sessions can go here
end

if test -d "$HOME/.zinit/plugins/asdf"
  source ~/.zinit/plugins/asdf/asdf.fish
end
