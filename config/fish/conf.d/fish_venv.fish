# https://github.com/ryoppippi/fish-poetry/blob/main/conf.d/fish-poetry.fish
# license: MIT (2024-02-04, 2e5369f)
#
# https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e
# originally from https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e

if command -s poetry > /dev/null

    # complete --command poetry --arguments "(env _POETRY_COMPLETE=complete-fish COMMANDLINE=(commandline -cp) poetry)" -f

    # function that loads environment variables from a file
    function posix-source
        for i in (cat $argv)
            if test (echo $i | sed -E 's/^[[:space:]]*(.).+$/\\1/g') != "#" && test -n $i
                set arr (string split -m1 = $i)
                set -gx $arr[1] $arr[2]
            end
        end
    end


    function __poetry_shell_activate --on-variable PWD
        if status --is-command-substitution
            return
        end
        if not test -e "$PWD/pyproject.toml"
            if not string match -q "$__poetry_fish_initial_pwd"/'*' "$PWD/"
                set -U __poetry_fish_final_pwd "$PWD"
                exit
            end
            return
        end

        if not test -n "$POETRY_ACTIVE"
          if poetry env info -p >/dev/null 2>&1
            set -x __poetry_fish_initial_pwd "$PWD"
            if test "$FISH_POETRY_LOAD_ENV" -a -e "$PWD/.env"
                echo "Setting environment variables..."
                posix-source $PWD/.env
            end

            poetry shell --quiet --no-ansi

            set -e __poetry_fish_initial_pwd
            if test -n "$__poetry_fish_final_pwd"
                cd "$__poetry_fish_final_pwd"
                set -e __poetry_fish_final_pwd
            end
          end
        end
    end
    __poetry_shell_activate
else
    function poetry -d "https://python-poetry.org"
        echo "Install https://python-poetry.org to use this plugin." > /dev/stderr
        return 1
    end
end

# Based on https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e
# Based on https://gist.github.com/bastibe/c0950e463ffdfdfada7adf149ae77c6f
# Based on https://github.com/nakulj/auto-venv/
# Changes:
# * Instead of overriding cd, we detect directory change. This allows the script to work
#   for other means of cd, such as z.
# * Update syntax to work with new versions of fish.
# * Prevent recursive handling of virtualenv activation
# * Safer activation and deactivation process

# Global flag to track if we're in the middle of handling venv
set -g __VENV_HANDLING 0

function __safe_activate_venv
    # Save current state
    set -l old_path $PATH
    set -l old_pythonhome $PYTHONHOME
    
    # Set up the environment
    set -gx VIRTUAL_ENV (dirname (dirname $argv[1]))
    set -gx _OLD_VIRTUAL_PATH $PATH
    set -gx PATH "$VIRTUAL_ENV/bin" $PATH
    
    # Handle PYTHONHOME
    if set -q PYTHONHOME
        set -gx _OLD_VIRTUAL_PYTHONHOME $PYTHONHOME
        set -e PYTHONHOME
    end
    
    # Set prompt
    set -gx VIRTUAL_ENV_PROMPT (basename "$VIRTUAL_ENV")
end

function __auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
    status --is-command-substitution; and return
    test "$__VENV_HANDLING" -eq 1; and return
    
    set -g __VENV_HANDLING 1

    # Check if we are inside a git repository
    if git rev-parse --show-toplevel &>/dev/null
        set dir (realpath (git rev-parse --show-toplevel))
    else
        set dir (pwd -P)
    end

    # Find a virtual environment in the directory
    set -l VENV_DIR_NAMES env .env venv .venv
    set -l venv_dir ""
    for name in $VENV_DIR_NAMES
        if test -e "$dir/$name/bin/activate.fish"
            set venv_dir "$dir/$name"
            break
        end
    end

    # Activate venv if it was found and not activated before
    if test -n "$venv_dir" -a "$VIRTUAL_ENV" != "$venv_dir" -a -e "$venv_dir/bin/activate.fish"
        __safe_activate_venv "$venv_dir/bin/activate.fish"
    # Deactivate venv if it is activated but we're no longer in a directory with a venv
    else if test -n "$VIRTUAL_ENV" -a -z "$venv_dir"
        # Save PATH before deactivation
        set -l old_path $PATH
        
        # Try to deactivate safely
        if functions -q deactivate
            deactivate
            # Restore PATH if it was unset
            if test -z "$PATH"
                set -gx PATH $old_path
            end
        else
            # Manual cleanup if deactivate isn't available
            set -e VIRTUAL_ENV
            set -e _OLD_VIRTUAL_PATH
            set -e _OLD_VIRTUAL_PYTHONHOME
            set -e PYTHONHOME
            set -e VIRTUAL_ENV_PROMPT
            set -gx PATH $old_path
        end
    end

    set -g __VENV_HANDLING 0
end

# Only run initial check if we're not already handling venv
if test "$__VENV_HANDLING" -eq 0
    __auto_source_venv
end
