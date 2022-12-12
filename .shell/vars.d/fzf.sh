#!/bin/zsh

if [ -z "$IGNORE_FILE_EXT" ]; then  # No ignores set

    export FZF_FIND_COMMAND="find . -path '*/\.*' -prune -o -type f -print -o -type l -print"

    export FZF_DEFAULT_COMMAND="(git ls-files --recurse-submodules & git ls-files --exclude-standard --others ||
        ${FZF_FIND_COMMAND} | \
            sed s/^..// \
        ) 2> /dev/null"

    export FZF_DEFAULT_COMMAND='(git ls-files --recurse-submodules ||
        find . -path "*/\.*" -prune -o -type f -print -o -type l -print |
    sed s/^..//) 2> /dev/null'

else  # Exists
    export FZF_CUSTOM_GREP_IGNORE="grep --ignore-case --invert-match -e '.*[.]\(\
        ${IGNORE_FILE_EXT} \
        \)' -e '.*\(${IGNORE_FILE_WILD}\).*'
    "

    export FZF_FIND_COMMAND="find . -path '*/\.*' -prune -o -type f -print -o -type l \
    \( -iname '.*\($IGNORE_FILE_WILD\).*' -o -iname '.*[.]\($IGNORE_FILE_EXT\)' \) -print"

    export FZF_DEFAULT_COMMAND="(git ls-files --recurse-submodules & git ls-files --exclude-standard --others ||
        ${FZF_FIND_COMMAND} | \
            sed s/^..// \
        ) | ${FZF_CUSTOM_GREP_IGNORE} 2> /dev/null"

    export FZF_CTRL_T_COMMAND="$FZF_FIND_COMMAND | ${FZF_CUSTOM_GREP_IGNORE} 2> /dev/null"
fi
