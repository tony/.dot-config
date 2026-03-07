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

    # Startup mode:
    # - default: full behavior — tools available immediately at startup
    # - fast: opt-in lower-latency mode (skips hook bootstrap at activate time)
    set -q MISE_STARTUP_MODE; or set -g MISE_STARTUP_MODE default

    # Lazy activation - defer hook-env until command execution
    set -gx mise_fish_mode eval_after_arrow
    # Only run full config check on directory change, not every prompt
    set -gx MISE_HOOK_ENV_CHPWD_ONLY true
    # Cache filesystem stat checks for 5 seconds (helps on WSL2/NFS)
    set -gx MISE_HOOK_ENV_CACHE_TTL 5s

    # -----------------------------------------------------------------------
    # Two-layer caching strategy for mise startup
    # -----------------------------------------------------------------------
    #
    # Problem:
    #   `mise activate fish` generates code that calls `mise hook-env` at
    #   startup to resolve tool versions and inject them into PATH/env.
    #   Without cached __MISE_DIFF state, this resolution does a full scan
    #   of all configured tools, taking ~190ms on systems with many runtimes.
    #
    # Solution:
    #   Layer 1 — Cache the `mise activate fish --no-hook-env` output.
    #             This provides the mise wrapper function, event hooks, and
    #             base env setup (~2ms to source from cache).
    #
    #   Layer 2 — Cache the `mise hook-env -s fish` output separately.
    #             This provides the resolved tool paths (PATH, GOROOT, etc.)
    #             and the __MISE_DIFF/__MISE_SESSION state that makes future
    #             hook-env calls fast (~1ms to source from cache).
    #
    # Cache invalidation:
    #   Layer 1 invalidates on: mise binary signature + startup mode
    #   Layer 2 invalidates on: mise binary signature + all tool-version
    #   config files (global and local). This ensures tool path changes are
    #   picked up immediately without waiting for the first prompt.
    #
    # When cache is valid (typical case):
    #   0 mise processes spawned, ~5ms total startup
    #
    # When cache is stale:
    #   2 mise processes spawned (activate + hook-env), full resolution
    #
    # Correctness guarantee:
    #   Even with cached hook-env, the --on-event fish_prompt hook still runs
    #   at the first interactive prompt, which catches any tool changes that
    #   occurred after the cache was written (e.g., editing .tool-versions
    #   between shell sessions).
    # -----------------------------------------------------------------------

    # _mise_file_signature — stat-based file identity for cache invalidation
    #
    # Returns "path:mtime:size" for a file, suitable for change detection.
    # Tries Linux stat first, falls back to BSD stat for macOS.
    # Returns failure (1) if the file doesn't exist or can't be stat'd.
    function _mise_file_signature -a file
        test -n "$file" -a -e "$file"; or return 1
        set -l sig
        set sig (command stat -Lc '%Y:%s' "$file" 2>/dev/null)
        or set sig (command stat -Lf '%m:%z' "$file" 2>/dev/null)
        or return 1
        echo "$file:$sig"
    end

    # _mise_build_hookenv_signature — build a composite signature for hook-env cache
    #
    # The hook-env output depends on which tools are configured and their versions.
    # We track every file that could change the tool resolution:
    #   - The mise binary itself (upgrades change behavior)
    #   - Global config: ~/.config/mise/config.toml
    #   - Global tool versions: ~/.tool-versions
    #   - Local configs in CWD: .tool-versions, .mise.toml, mise.toml
    #
    # Each file contributes its mtime:size to the signature. Missing files
    # contribute "absent" so that creating a new config file invalidates.
    function _mise_build_hookenv_signature -a mise_bin
        set -l parts
        set -a parts (_mise_file_signature "$mise_bin"; or echo "$mise_bin:unknown")
        for f in ~/.config/mise/config.toml ~/.tool-versions .tool-versions .mise.toml mise.toml
            set -a parts (_mise_file_signature "$f"; or echo "$f:absent")
        end
        string join "|" $parts
    end

    # _mise_activate_cached — Layer 1: cache mise activate --no-hook-env output
    #
    # Always uses --no-hook-env regardless of MISE_STARTUP_MODE. The hook-env
    # result is handled separately by Layer 2 (_mise_hookenv_cached).
    # This avoids spawning a mise process when the cache is valid.
    #
    # Cache files:
    #   $cache_dir/mise_activate.fish       — the cached activate script
    #   $cache_dir/mise_activate.signature   — binary sig for invalidation
    function _mise_activate_cached
        set -l cache_dir (set -q XDG_CACHE_HOME; and echo "$XDG_CACHE_HOME/fish"; or echo "$HOME/.cache/fish")
        set -l cache_file $cache_dir/mise_activate.fish
        set -l signature_file $cache_dir/mise_activate.signature

        set -l mise_bin (command -s mise)
        set -l current_signature (_mise_file_signature "$mise_bin"; or echo "$mise_bin:unknown")

        # Check cache validity — only the binary signature matters for Layer 1
        if test -f "$cache_file" -a -f "$signature_file"
            set -l cached_signature ""
            if read -l cached_signature < "$signature_file"
                if test "$current_signature" = "$cached_signature"
                    source "$cache_file"
                    return
                end
            end
        end

        # Cache miss — generate and store.
        # Always use --no-hook-env: Layer 2 handles tool resolution.
        mkdir -p "$cache_dir"
        mise activate fish --no-hook-env > "$cache_file"
        echo "$current_signature" > "$signature_file"
        source "$cache_file"
    end

    # _mise_hookenv_cached — Layer 2: cache mise hook-env output
    #
    # This is the expensive part: `mise hook-env -s fish` resolves all tool
    # versions and outputs PATH, GOROOT, JAVA_HOME, etc. Without cached
    # __MISE_DIFF state, this takes ~190ms for full resolution.
    #
    # By caching the output and sourcing it directly, we get:
    #   - Immediate tool availability in PATH (no waiting for first prompt)
    #   - __MISE_DIFF and __MISE_SESSION pre-populated (future hook-env: ~9ms)
    #   - Zero mise processes spawned on cache hit (~1ms)
    #
    # In "fast" startup mode, this layer is skipped entirely — tools become
    # available lazily at the first prompt via the --on-event fish_prompt hook.
    #
    # Cache files:
    #   $cache_dir/mise_hookenv.fish       — the cached hook-env output
    #   $cache_dir/mise_hookenv.signature   — composite config sig
    function _mise_hookenv_cached
        set -l cache_dir (set -q XDG_CACHE_HOME; and echo "$XDG_CACHE_HOME/fish"; or echo "$HOME/.cache/fish")
        set -l cache_file $cache_dir/mise_hookenv.fish
        set -l signature_file $cache_dir/mise_hookenv.signature

        set -l mise_bin (command -s mise)
        set -l current_signature (_mise_build_hookenv_signature "$mise_bin")

        # Check cache validity — includes all tool-version config files
        if test -f "$cache_file" -a -f "$signature_file"
            set -l cached_signature ""
            if read -l cached_signature < "$signature_file"
                if test "$current_signature" = "$cached_signature"
                    source "$cache_file"
                    return
                end
            end
        end

        # Cache miss — run mise hook-env and store the output.
        # This is the ~190ms path that only runs when config files change.
        mkdir -p "$cache_dir"
        command mise hook-env -s fish > "$cache_file"
        echo "$current_signature" > "$signature_file"
        source "$cache_file"
    end

    # Initialize mise with two-layer caching
    _mise_activate_cached

    # Layer 2: resolve tool paths from cache (skipped in fast mode)
    if test "$MISE_STARTUP_MODE" != fast
        _mise_hookenv_cached
    end

    # Set up completions (one-time generation, cached by fish itself)
    if not test -f ~/.config/fish/completions/mise.fish
        mkdir -p ~/.config/fish/completions
        mise completion fish > ~/.config/fish/completions/mise.fish
    end
end

# Enable asdf compatibility mode (for projects using .tool-versions)
set -x MISE_ASDF_COMPAT true
