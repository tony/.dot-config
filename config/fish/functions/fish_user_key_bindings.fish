function fish_user_key_bindings
    # Use emacs key bindings
    fish_default_key_bindings -M insert

    # Add vi key bindings on top
    fish_vi_key_bindings --no-erase insert

    # FZF key bindings if available
    if type -q fzf_key_bindings
        fzf_key_bindings
    end

    # Edit command in external editor (like Zsh's edit-command-line)
    bind --user \cx\ce edit_command_buffer
    bind --user -M insert \cx\ce edit_command_buffer
    bind --user -M visual \cx\ce edit_command_buffer

    # History substring search bindings
    bind --user -M insert \e[A history-prefix-search-backward
    bind --user -M insert \e[B history-prefix-search-forward
end
