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

    # Initialize mise
    mise activate fish | source
    
    # Set up completions
    if not test -f ~/.config/fish/completions/mise.fish
        mkdir -p ~/.config/fish/completions
        mise completion fish > ~/.config/fish/completions/mise.fish
    end
end

# Enable asdf compatibility mode (for projects using .tool-versions)
set -x MISE_ASDF_COMPAT true
