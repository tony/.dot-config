# Poetry environment auto-activation for Poetry 2.0+
# Uses `poetry env activate` instead of deprecated `poetry shell`

if command -s poetry >/dev/null

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

        # Check if poetry has an environment for this project
        if poetry env info -p >/dev/null 2>&1
            # Load .env file if configured
            if test "$FISH_POETRY_LOAD_ENV" -a -e "$PWD/.env"
                echo "Setting environment variables..."
                posix-source $PWD/.env
            end

            # Activate the poetry environment (Poetry 2.0+ style)
            # This sources the activate.fish script directly
            set -l venv_path (poetry env info -p 2>/dev/null)
            if test -n "$venv_path" -a -f "$venv_path/bin/activate.fish"
                source "$venv_path/bin/activate.fish"
            end
        end
    end

    # Check if this shell was started in a directory that has a poetry project
    __poetry_env_activate
else
    function poetry -d "https://python-poetry.org"
        echo "Install https://python-poetry.org to use this plugin." >/dev/stderr
        return 1
    end
end
