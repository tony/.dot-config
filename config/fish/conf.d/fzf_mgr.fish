# First ensure the functions are loaded
if not functions -q fzf_mgr_ensure
    source (status dirname)/../functions/fzf_mgr.fish
end

# Skip fzf setup in test mode
if not set -q FISH_TEST
    # Load fzf configuration
    set -l conf_file (status dirname)/fzf.conf.fish
    if test -f $conf_file
        source $conf_file
    end

    # Ensure fzf is installed with the correct version
    if not command -q fzf; or test "$FZF_AUTO_UPDATE" = "true"
        fzf_mgr_ensure
    end
end 