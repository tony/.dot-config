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

function __fzf_mgr_get_install_dir
    # Use FZF_INSTALL_DIR if set, otherwise use test directory in test mode or default directory
    if set -q FZF_INSTALL_DIR
        echo "$FZF_INSTALL_DIR"
    else if set -q FISH_TEST; and set -q test_temp_dir
        echo "$test_temp_dir/local/bin"
    else
        echo "$HOME/.local/bin"
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
    
    # Determine system architecture and OS
    set -l arch (uname -m)
    set -l os (uname -s | string lower)
    
    __fzf_mgr_log "DEBUG" "System: $os, Architecture: $arch"
    
    # Map architecture names
    switch $arch
        case x86_64
            set arch amd64
            __fzf_mgr_log "DEBUG" "Mapped x86_64 to amd64"
        case aarch64
            set arch arm64
            __fzf_mgr_log "DEBUG" "Mapped aarch64 to arm64"
        case '*'
            __fzf_mgr_log "ERROR" "Unsupported architecture: $arch"
            popd
            rm -rf $temp_dir
            return 1
    end
    
    # Map OS names
    switch $os
        case linux darwin
            __fzf_mgr_log "DEBUG" "Using $os platform"
        case '*'
            __fzf_mgr_log "ERROR" "Unsupported operating system: $os"
            popd
            rm -rf $temp_dir
            return 1
    end
    
    # Strip 'v' prefix if present for filename
    set -l ver_no_prefix (string replace -r '^v' '' $target_ver)
    __fzf_mgr_log "DEBUG" "Version without prefix: $ver_no_prefix"
    
    # Construct platform-specific filename
    set -l filename
    if test $os = darwin
        set filename "fzf-$ver_no_prefix-darwin_$arch.zip"
    else
        set filename "fzf-$ver_no_prefix-$os"_"$arch.tar.gz"
    end
    __fzf_mgr_log "DEBUG" "Archive filename: $filename"
    
    set -l download_url "https://github.com/junegunn/fzf/releases/download/$target_ver/$filename"
    __fzf_mgr_log "DEBUG" "Download URL: $download_url"
    
    # Download the file first to check if it exists
    set -l archive $temp_dir/fzf.archive
    if not curl -L -f -o $archive $download_url
        __fzf_mgr_log "ERROR" "Failed to download fzf: $download_url"
        popd
        rm -rf $temp_dir
        return 1
    end
    
    # Extract based on archive type
    if string match -q '*.zip' $filename
        if not unzip $archive
            __fzf_mgr_log "ERROR" "Failed to extract fzf zip archive"
            popd
            rm -rf $temp_dir
            return 1
        end
    else
        if not tar xzf $archive
            __fzf_mgr_log "ERROR" "Failed to extract fzf tar.gz archive"
            popd
            rm -rf $temp_dir
            return 1
        end
    end
    
    chmod +x fzf
    
    # Get installation directory
    set -l install_dir (__fzf_mgr_get_install_dir)
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
        __fzf_mgr_log "INFO" "Installing/updating fzf..."
        fzf_mgr_install $FZF_VERSION
    end
end 