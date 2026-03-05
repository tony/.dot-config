# Auto-activate Python virtual environments on directory change
# Poetry projects are handled by conf.d/fish-poetry.fish
#
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
# Cache last resolved project directory to avoid repeated git probes.
set -g __AUTO_VENV_LAST_PWD ""
set -g __AUTO_VENV_LAST_DIR ""
set -g __AUTO_VENV_REPO_ROOT ""

function __resolve_venv_search_dir --description "Resolve venv search dir with git root caching"
    set -l pwd_real (pwd -P)

    if test "$pwd_real" = "$__AUTO_VENV_LAST_PWD" -a -n "$__AUTO_VENV_LAST_DIR"
        echo "$__AUTO_VENV_LAST_DIR"
        return
    end

    if test -n "$__AUTO_VENV_REPO_ROOT"
        set -l repo_root_regex (string escape --style=regex -- "$__AUTO_VENV_REPO_ROOT")
        if string match -qr "^"$repo_root_regex"(/|\$)" -- "$pwd_real"
            set -g __AUTO_VENV_LAST_PWD "$pwd_real"
            set -g __AUTO_VENV_LAST_DIR "$__AUTO_VENV_REPO_ROOT"
            echo "$__AUTO_VENV_REPO_ROOT"
            return
        end
    end

    set -l repo_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$repo_root"
        set -l resolved_repo_root (realpath "$repo_root" 2>/dev/null)
        if test -z "$resolved_repo_root"
            set resolved_repo_root "$repo_root"
        end
        set -g __AUTO_VENV_REPO_ROOT "$resolved_repo_root"
        set -g __AUTO_VENV_LAST_DIR "$resolved_repo_root"
    else
        set -g __AUTO_VENV_REPO_ROOT ""
        set -g __AUTO_VENV_LAST_DIR "$pwd_real"
    end

    set -g __AUTO_VENV_LAST_PWD "$pwd_real"
    echo "$__AUTO_VENV_LAST_DIR"
end

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

    set dir (__resolve_venv_search_dir)

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
