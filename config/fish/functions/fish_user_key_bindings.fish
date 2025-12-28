function fish_user_key_bindings
    # Hybrid emacs/vi mode: Start with emacs bindings, layer vi on top
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert

    # Edit command in external editor (Ctrl-x Ctrl-e, like Zsh)
    bind --user ctrl-x,ctrl-e edit_command_buffer
    bind --user -M insert ctrl-x,ctrl-e edit_command_buffer
    bind --user -M visual ctrl-x,ctrl-e edit_command_buffer

    # History prefix search with arrow keys
    bind --user -M insert up history-prefix-search-backward
    bind --user -M insert down history-prefix-search-forward
    bind --user -M default up history-prefix-search-backward
    bind --user -M default down history-prefix-search-forward

    # FZF bindings - configurable via FZF_USE_ZSH_BINDINGS
    if type -q fzf_configure_bindings
        if test "$FZF_USE_ZSH_BINDINGS" != "0"
            # Zsh-style: Ctrl-T files, Ctrl-R history, Alt-C cd
            fzf_configure_bindings --directory=ctrl-t --history=ctrl-r --variables= --processes=
            if type -q _fzf_search_directory
                bind --user alt-c _fzf_search_directory
                bind --user -M insert alt-c _fzf_search_directory
            end
        else
            # Native fzf.fish bindings
            fzf_configure_bindings
        end
    else if type -q fzf_key_bindings
        fzf_key_bindings
    end
end
