# Only run in interactive mode or CI
if not status is-interactive && test "$CI" != true
    exit
end

# Check if IGNORE_FILE_EXT is set
if test -z "$IGNORE_FILE_EXT"
    # No ignores set
    set -x FZF_FIND_COMMAND "find . -path '*/.*' -prune -o \( -type f -o -type l \) -print"
else
    # Build grep command for ignoring patterns
    set -x FZF_CUSTOM_GREP_IGNORE "grep -E --ignore-case --invert-match \
        -e '.*\.($IGNORE_FILE_EXT)' \
        -e '.*($IGNORE_FILE_WILD).*'"

    set -x FZF_FIND_COMMAND "find . -path '*/.*' -prune -o \( -type f -o -type l \) -print \
        | $FZF_CUSTOM_GREP_IGNORE"
end

# Strip leading './' from find output
set -x STRIP_CMD "sed 's|^\./||'"

# If git ls-files fails, fallback to raw find
set -x FZF_DEFAULT_COMMAND "begin; \
    git ls-files --recurse-submodules 2>/dev/null; \
    or git ls-files --exclude-standard --others 2>/dev/null; \
    or eval $FZF_FIND_COMMAND; \
    end | $STRIP_CMD"

# Set Ctrl+T to use the same command
set -x FZF_CTRL_T_COMMAND "$FZF_FIND_COMMAND | $STRIP_CMD"

# Configure FZF default options
set -x FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border --cycle"

# Configure key bindings
function fish_user_key_bindings
    # Standard bindings
    fzf_key_bindings

    # Additional custom bindings can go here
    bind \ct '__fzf_search_current_dir'
    bind \cr '__fzf_search_history'
    bind \ec '__fzf_search_directory'
end 