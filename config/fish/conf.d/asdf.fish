set -x MISE_DATA_DIR ~/.config/mise

# Detect if mise is installed
if not command -sq mise
    # If mise is not found, try to install it
    echo "mise not found, installing..."
    if command -sq curl
        curl https://mise.run | sh
    else
        echo "curl not found, please install mise manually: https://mise.run"
    end
end

if command -sq mise
    # Add mise to PATH if it's not already there
    fish_add_path ~/.local/bin

    # Lazy activation - defer hook-env until command execution
    set -gx mise_fish_mode eval_after_arrow
    # Only run full config check on directory change, not every prompt
    set -gx MISE_HOOK_ENV_CHPWD_ONLY true

    # Evalcache for mise activate - caches generated shell code
    # Invalidates when mise version changes
    function _mise_activate_cached
        set -l cache_dir ~/.cache/fish
        set -l cache_file $cache_dir/mise_activate.fish
        set -l version_file $cache_dir/mise_activate.version

        # Get current mise version (fast - reads from binary)
        set -l current_version (mise --version 2>/dev/null | string split ' ')[2]

        # Check cache validity
        if test -f "$cache_file" -a -f "$version_file"
            set -l cached_version (cat "$version_file" 2>/dev/null)
            if test "$current_version" = "$cached_version"
                source "$cache_file"
                return
            end
        end

        # Generate and cache
        mkdir -p "$cache_dir"
        mise activate fish > "$cache_file"
        echo "$current_version" > "$version_file"
        source "$cache_file"
    end

    # Initialize mise with caching
    _mise_activate_cached

    # Set up completions
    if not test -f ~/.config/fish/completions/mise.fish
        mkdir -p ~/.config/fish/completions
        mise completion fish > ~/.config/fish/completions/mise.fish
    end
end

# Enable asdf compatibility mode (for projects using .tool-versions)
set -x MISE_ASDF_COMPAT true
