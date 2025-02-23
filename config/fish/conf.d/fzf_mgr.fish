# Set default fzf version if not already set
if not set -q FZF_VERSION
    # Default to latest version
    set -gx FZF_VERSION "latest"
end

# Only run the check if we're in an interactive shell
if status is-interactive
    # Check if we need to run fzf installation/update
    if not command -q fzf; or test "$FZF_AUTO_UPDATE" = "true"
        fzf_mgr_ensure
    end
end 