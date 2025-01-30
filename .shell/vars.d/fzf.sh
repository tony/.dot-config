#!/usr/bin/env zsh

# Use [[ ... ]] for zsh
if [[ -z "$IGNORE_FILE_EXT" ]]; then
    # No ignores
    FZF_FIND_COMMAND='find . -path "*/.*" -prune -o \( -type f -o -type l \) -print'
else
    # Build a grep command that ignores certain extensions/patterns
    FZF_CUSTOM_GREP_IGNORE="grep -E --ignore-case --invert-match \
        -e '.*\.($IGNORE_FILE_EXT)' \
        -e '.*($IGNORE_FILE_WILD).*'"

    FZF_FIND_COMMAND="find . -path '*/.*' -prune -o \( -type f -o -type l \) -print \
        | $FZF_CUSTOM_GREP_IGNORE"
fi

# Remove leading './' from find output
# Could do sed 's|^\./||'
# or cut -c3- if you trust lines always start with './'
STRIP_CMD="sed 's|^\./||'"

# If git ls-files fails, fallback to raw find
# Use && or ; to run them in sequence
FZF_DEFAULT_COMMAND="( \
    (git ls-files --recurse-submodules; \
    git ls-files --exclude-standard --others) 2>/dev/null || \
    $FZF_FIND_COMMAND \
  ) | $STRIP_CMD 2>/dev/null"

export FZF_FIND_COMMAND
export FZF_DEFAULT_COMMAND

# If you want the Ctrl+T command to also do the ignoring:
export FZF_CTRL_T_COMMAND="$FZF_FIND_COMMAND | $STRIP_CMD 2>/dev/null"
