# Poetry environment auto-activation for Poetry 2.0+
# Uses `poetry env activate` instead of deprecated `poetry shell`
# Startup note:
# Do not resolve `poetry` globally on shell startup. Check it lazily only
# inside potential poetry projects to keep startup overhead low.

# function that loads environment variables from a file
function posix-source
    for i in (cat $argv)
        if test (echo $i | sed -E 's/^[[:space:]]*(.).+$/\\1/g') != "#" && test -n $i
            set arr (string split -m1 = $i)
            set -gx $arr[1] $arr[2]
        end
    end
end

function __poetry_env_activate --on-variable PWD
    if status --is-command-substitution
        return
    end

    # Skip if not in a poetry project
    if not test -e "$PWD/pyproject.toml"
        return
    end

    # Skip if already in a virtual environment
    if test -n "$VIRTUAL_ENV"
        return
    end

    # Resolve poetry only for poetry project directories.
    if not type -q poetry
        return
    end

    # Activate the poetry environment (Poetry 2.0+ style)
    # This sources the activate.fish script directly
    set -l venv_path (poetry env info -p 2>/dev/null)
    if test -n "$venv_path" -a -f "$venv_path/bin/activate.fish"
        # Load .env file if configured
        if test "$FISH_POETRY_LOAD_ENV" -a -e "$PWD/.env"
            posix-source "$PWD/.env"
        end

        source "$venv_path/bin/activate.fish"
    end
end

# Preserve previous behavior by default: run one activation check at startup.
# Set FISH_POETRY_SKIP_STARTUP_CHECK=1 to skip this initial probe.
if not set -q FISH_POETRY_SKIP_STARTUP_CHECK
    __poetry_env_activate
end
