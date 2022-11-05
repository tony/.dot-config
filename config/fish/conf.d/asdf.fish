set -x ASDF_DATA_DIR ~/.config/.asdf
set -x ASDF_DIR ~/.zinit/plugins/asdf
set -x ASDF_CONFIG_FILE ~/.asdfrc

if test -n "$ASDF_DIR" -a -d "$ASDF_DIR"
    source $ASDF_DIR/asdf.fish
else if test -f ~/.asdf/asdf.fish
    source ~/.asdf/asdf.fish
else if test -f /usr/local/opt/asdf/asdf.fish
    source /usr/local/opt/asdf/asdf.fish
else if test -f /opt/homebrew/opt/asdf/asdf.fish
    source /opt/homebrew/opt/asdf/asdf.fish
end
