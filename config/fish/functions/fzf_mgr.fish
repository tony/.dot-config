function __fzf_mgr_log -a level message
    # Only log if FISH_DEBUG is set
    if not set -q FISH_DEBUG
        return
    end
    
    # Format the message based on level
    switch $level
        case DEBUG INFO ERROR
            echo "[$level] $message" >&2
    end
end

function fzf_mgr_get_version
    __fzf_mgr_log "DEBUG" "Checking installed fzf version"
    if command -q fzf
        set -l ver_str (fzf --version 2>/dev/null | string split ' ')[1]
        if test -n "$ver_str"
            __fzf_mgr_log "INFO" "Found fzf version: $ver_str"
            echo $ver_str
            return 0
        end
        __fzf_mgr_log "ERROR" "Failed to get fzf version output"
        return 1
    end
    __fzf_mgr_log "INFO" "fzf not found in PATH"
    return 1
end

function fzf_mgr_get_latest_version
    __fzf_mgr_log "DEBUG" "Fetching latest fzf version from GitHub"
    if not command -q curl
        __fzf_mgr_log "ERROR" "curl not found in PATH"
        return 1
    end
    
    set -l api_response (curl -s https://api.github.com/repos/junegunn/fzf/releases/latest)
    if test $status -ne 0
        __fzf_mgr_log "ERROR" "Failed to fetch from GitHub API"
        return 1
    end
    
    # Extract version using a more precise regex
    set -l latest_ver (echo $api_response | string match -r '"tag_name":\s*"(v[0-9]+\.[0-9]+\.[0-9]+)"' | tail -n1)
    if test -n "$latest_ver"
        __fzf_mgr_log "INFO" "Latest version from GitHub: $latest_ver"
        echo $latest_ver
        return 0
    end
    __fzf_mgr_log "ERROR" "Failed to parse version from GitHub response"
    return 1
end

function fzf_mgr_needs_update
    __fzf_mgr_log "DEBUG" "Checking if fzf needs update"
    set -l current_ver (fzf_mgr_get_version)
    if test $status -eq 1
        __fzf_mgr_log "INFO" "fzf needs installation"
        return 0 # needs installation
    end
    
    set -l target_ver $FZF_VERSION
    if test -z "$target_ver"; or test "$target_ver" = "latest"
        set target_ver (fzf_mgr_get_latest_version)
        if test $status -eq 1
            __fzf_mgr_log "ERROR" "Failed to get latest version"
            return 1
        end
    end
    
    # Compare versions (strip 'v' prefix if present)
    set current_ver (string replace -r '^v' '' $current_ver)
    set target_ver (string replace -r '^v' '' $target_ver)
    
    if test "$current_ver" != "$target_ver"
        __fzf_mgr_log "INFO" "Update needed: $current_ver -> $target_ver"
        return 0
    end
    __fzf_mgr_log "INFO" "fzf is up to date ($current_ver)"
    return 1
end

function fzf_mgr_install
    set -l target_ver $argv[1]
    if test -z "$target_ver"; or test "$target_ver" = "latest"
        set target_ver (fzf_mgr_get_latest_version)
        if test $status -eq 1
            __fzf_mgr_log "ERROR" "Failed to get latest version"
            return 1
        end
    end
    
    __fzf_mgr_log "INFO" "Installing fzf version $target_ver"
    
    # Check required commands
    if not command -q curl
        __fzf_mgr_log "ERROR" "curl not found in PATH"
        return 1
    end
    if not command -q tar
        __fzf_mgr_log "ERROR" "tar not found in PATH"
        return 1
    end
    
    # Create temporary directory
    set -l temp_dir (mktemp -d)
    if test $status -ne 0
        __fzf_mgr_log "ERROR" "Failed to create temporary directory"
        return 1
    end
    
    pushd $temp_dir
    
    # Download and install fzf
    set -l download_url "https://github.com/junegunn/fzf/releases/download/$target_ver/fzf-$target_ver-linux_amd64.tar.gz"
    __fzf_mgr_log "DEBUG" "Downloading from: $download_url"
    
    if not curl -L $download_url | tar xz
        __fzf_mgr_log "ERROR" "Failed to download or extract fzf"
        popd
        rm -rf $temp_dir
        return 1
    end
    
    chmod +x fzf
    
    # Use test directory if in test mode, otherwise use ~/.local/bin
    set -l install_dir
    if set -q FISH_TEST
        set install_dir $test_temp_dir/local/bin
    else
        set install_dir $HOME/.local/bin
    end
    
    if not test -d $install_dir
        mkdir -p $install_dir
    end
    
    __fzf_mgr_log "DEBUG" "Installing to: $install_dir"
    if not mv fzf $install_dir/
        __fzf_mgr_log "ERROR" "Failed to install fzf to $install_dir"
        popd
        rm -rf $temp_dir
        return 1
    end
    
    # Cleanup
    popd
    rm -rf $temp_dir
    
    # Verify installation
    if fzf_mgr_get_version >/dev/null
        __fzf_mgr_log "INFO" "Successfully installed fzf $target_ver"
        return 0
    end
    __fzf_mgr_log "ERROR" "Failed to verify fzf installation"
    return 1
end

function fzf_mgr_ensure
    __fzf_mgr_log "DEBUG" "Ensuring fzf is installed with correct version"
    if fzf_mgr_needs_update
        echo "Installing/updating fzf..."
        fzf_mgr_install $FZF_VERSION
    end
end 