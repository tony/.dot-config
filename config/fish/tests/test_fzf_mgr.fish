#!/usr/bin/env fish

# Verify we're running in test mode
if not set -q FISH_TEST
    echo "Error: Tests must be run with FISH_TEST environment variable set"
    exit 1
end

# Load all required functions
for func in fzf_mgr_get_version fzf_mgr_get_latest_version fzf_mgr_needs_update fzf_mgr_install fzf_mgr_ensure __fzf_mgr_log
    functions -q $func; or source (status dirname)/../functions/fzf_mgr.fish
end

# Setup and teardown functions
function setup
    # Create a temporary test directory
    set -g test_temp_dir (mktemp -d)
    set -g original_path $PATH
    set -g original_fzf_install_dir $FZF_INSTALL_DIR
    
    # Create test bin directories
    mkdir -p $test_temp_dir/bin
    mkdir -p $test_temp_dir/local/bin
    
    # Add test directories to PATH (local/bin first for precedence)
    set -gx PATH $test_temp_dir/local/bin $test_temp_dir/bin $PATH
    
    # Save original environment
    set -g original_fzf_version $FZF_VERSION
    set -g original_fish_function_path $fish_function_path
    
    # Override FZF_INSTALL_DIR to prevent writing to real system
    set -gx FZF_INSTALL_DIR "$test_temp_dir/local/bin"
end

function teardown
    # Restore original PATH
    set -gx PATH $original_path
    
    # Restore original environment
    set -gx FZF_VERSION $original_fzf_version
    set -gx fish_function_path $original_fish_function_path
    set -gx FZF_INSTALL_DIR $original_fzf_install_dir
    
    # Clean up test directory
    rm -rf $test_temp_dir
end

# Helper function to run a test
function run_test
    set -l test_name $argv[1]
    set -l test_fn $argv[2..-1]
    echo -n "Testing $test_name... "
    
    # Run setup before each test
    setup
    
    # Create a temporary file for test output
    set -l output_file (mktemp)
    
    # Run the test and capture its output and status
    eval $test_fn >$output_file 2>&1
    set -l test_status $status
    
    if test $test_status -eq 0
        set_color green
        echo "PASS"
        set_color normal
    else
        set_color red
        echo "FAIL"
        if test -s $output_file
            echo "Test output:"
            echo "------------"
            cat $output_file
            echo "------------"
        end
        set_color normal
    end
    
    # Clean up output file
    rm -f $output_file
    
    # Run teardown after each test
    teardown
    return $test_status
end

# Test sandbox validation
function test_sandbox_setup
    # Test that temporary directory exists and is writable
    test -d "$test_temp_dir"; or begin
        echo "Temporary directory not created"
        return 1
    end
    test -w "$test_temp_dir"; or begin
        echo "Temporary directory not writable"
        return 1
    end
    
    # Test that bin directories exist
    test -d "$test_temp_dir/bin"; or begin
        echo "Test bin directory not created"
        return 1
    end
    test -d "$test_temp_dir/local/bin"; or begin
        echo "Test local/bin directory not created"
        return 1
    end
    
    # Test PATH setup
    set -l first_path (string split : $PATH)[1]
    test "$first_path" = "$test_temp_dir/local/bin"; or begin
        echo "Expected first PATH entry: $test_temp_dir/local/bin"
        echo "Actual first PATH entry: $first_path"
        return 1
    end
    
    # Test FZF_INSTALL_DIR is sandboxed
    test "$FZF_INSTALL_DIR" = "$test_temp_dir/local/bin"; or begin
        echo "FZF_INSTALL_DIR not properly sandboxed"
        echo "Expected: $test_temp_dir/local/bin"
        echo "Actual: $FZF_INSTALL_DIR"
        return 1
    end
    
    # Test that we're not using real system directories
    not string match -q "$HOME/.local/bin*" $FZF_INSTALL_DIR; or begin
        echo "FZF_INSTALL_DIR points to real system directory"
        return 1
    end
    
    return 0
end

# Test environment variable handling
function test_env_vars
    # Test that original environment is saved
    test -n "$original_path"; or begin
        echo "original_path not set"
        return 1
    end
    test -n "$original_fzf_version"; or begin
        echo "original_fzf_version not set"
        return 1
    end
    test -n "$original_fish_function_path"; or begin
        echo "original_fish_function_path not set"
        return 1
    end
    test -n "$original_fzf_install_dir"; or begin
        echo "original_fzf_install_dir not set"
        return 1
    end
    
    # Test that environment variables are properly set
    test -n "$FISH_TEST"; or begin
        echo "FISH_TEST not set"
        return 1
    end
    test -n "$test_temp_dir"; or begin
        echo "test_temp_dir not set"
        return 1
    end
    test -n "$FZF_INSTALL_DIR"; or begin
        echo "FZF_INSTALL_DIR not set"
        return 1
    end
    
    return 0
end

# Test version checking
function test_get_version
    # Mock fzf for testing
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/fzf
    echo 'echo "0.42.0"' >> $test_temp_dir/bin/fzf
    chmod +x $test_temp_dir/bin/fzf
    
    set -l ver_str (fzf_mgr_get_version)
    test $status -eq 0; and string match -q -r '^[0-9]+\.[0-9]+\.[0-9]+$' (string replace -r '^v' '' $ver_str)
end

# Test latest version fetching
function test_get_latest_version
    # Mock curl for testing
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/curl
    echo 'echo \'{"tag_name": "v0.42.0", "name": "0.42.0"}\'' >> $test_temp_dir/bin/curl
    chmod +x $test_temp_dir/bin/curl
    
    set -l ver_str (fzf_mgr_get_latest_version)
    test $status -eq 0; and test "$ver_str" = "v0.42.0"
end

# Test needs update checking
function test_needs_update_with_current
    # Mock current version
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/fzf
    echo 'echo "0.42.0"' >> $test_temp_dir/bin/fzf
    chmod +x $test_temp_dir/bin/fzf
    
    set -l current_ver (fzf_mgr_get_version)
    set -gx FZF_VERSION $current_ver
    not fzf_mgr_needs_update
end

function test_needs_update_with_different
    # Mock current version
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/fzf
    echo 'echo "0.42.0"' >> $test_temp_dir/bin/fzf
    chmod +x $test_temp_dir/bin/fzf
    
    set -gx FZF_VERSION "v0.1.0" # Very old version
    fzf_mgr_needs_update
end

# Test installation
function test_install
    # Mock curl and tar for testing
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/curl
    echo 'echo \'{"tag_name": "v0.42.0", "name": "0.42.0"}\'' >> $test_temp_dir/bin/curl
    chmod +x $test_temp_dir/bin/curl
    
    # Mock tar to create a fake fzf binary
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/tar
    echo 'echo "#!/usr/bin/env fish" > fzf' >> $test_temp_dir/bin/tar
    echo 'echo "echo \"0.42.0\"" >> fzf' >> $test_temp_dir/bin/tar
    echo 'chmod +x fzf' >> $test_temp_dir/bin/tar
    chmod +x $test_temp_dir/bin/tar
    
    set -l test_ver "v0.42.0"
    fzf_mgr_install $test_ver
    test $status -eq 0; and begin
        set -l installed_ver (fzf_mgr_get_version)
        test "$installed_ver" = (string replace -r '^v' '' $test_ver)
    end
end

# Test auto-update functionality
function test_auto_update
    # Mock initial version
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/fzf
    echo 'echo "0.41.0"' >> $test_temp_dir/bin/fzf
    chmod +x $test_temp_dir/bin/fzf
    
    # Mock curl for latest version
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/curl
    echo 'echo \'{"tag_name": "v0.42.0", "name": "0.42.0"}\'' >> $test_temp_dir/bin/curl
    chmod +x $test_temp_dir/bin/curl
    
    # Mock tar for installation - create fzf in current directory
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/tar
    echo 'set -l args (string split " " -- $argv)' >> $test_temp_dir/bin/tar
    echo 'set -l dir (dirname $args[-1])' >> $test_temp_dir/bin/tar
    echo 'mkdir -p $dir' >> $test_temp_dir/bin/tar
    echo 'cd $dir' >> $test_temp_dir/bin/tar
    echo 'echo "#!/usr/bin/env fish" > fzf' >> $test_temp_dir/bin/tar
    echo 'echo "echo \"0.42.0\"" >> fzf' >> $test_temp_dir/bin/tar
    echo 'chmod +x fzf' >> $test_temp_dir/bin/tar
    chmod +x $test_temp_dir/bin/tar
    
    # Enable auto-update and set installation directory
    set -gx FZF_AUTO_UPDATE true
    set -gx FZF_VERSION latest
    set -gx FZF_INSTALL_DIR "$test_temp_dir/local/bin"
    
    # Run ensure and verify update
    begin
        fzf_mgr_ensure
        
        # Verify the new version is found in the correct location
        set -l fzf_path (which fzf)
        set -l new_ver (fzf_mgr_get_version)
        
        if not string match -q "$test_temp_dir/local/bin/fzf" $fzf_path
            echo "Expected fzf in: $test_temp_dir/local/bin/fzf"
            echo "Found fzf in: $fzf_path"
            echo "PATH: $PATH"
            echo "Local bin contents:"
            ls -la $test_temp_dir/local/bin
            return 1
        end
        
        if not test "$new_ver" = "0.42.0"
            echo "Expected version: 0.42.0"
            echo "Actual version: $new_ver"
            echo "PATH: $PATH"
            echo "FZF binary location: "$fzf_path
            echo "Local bin contents:"
            ls -la $test_temp_dir/local/bin
            return 1
        end
        return 0
    end
end

# Test custom installation directory
function test_custom_install_dir
    set -l custom_dir "$test_temp_dir/custom/bin"
    mkdir -p $custom_dir
    set -gx FZF_INSTALL_DIR $custom_dir
    
    # Mock curl and tar
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/curl
    echo 'echo \'{"tag_name": "v0.42.0", "name": "0.42.0"}\'' >> $test_temp_dir/bin/curl
    chmod +x $test_temp_dir/bin/curl
    
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/tar
    echo 'set -l args (string split " " -- $argv)' >> $test_temp_dir/bin/tar
    echo 'set -l dir (dirname $args[-1])' >> $test_temp_dir/bin/tar
    echo 'mkdir -p $dir' >> $test_temp_dir/bin/tar
    echo 'cd $dir' >> $test_temp_dir/bin/tar
    echo 'echo "#!/usr/bin/env fish" > fzf' >> $test_temp_dir/bin/tar
    echo 'echo "echo \"0.42.0\"" >> fzf' >> $test_temp_dir/bin/tar
    echo 'chmod +x fzf' >> $test_temp_dir/bin/tar
    chmod +x $test_temp_dir/bin/tar
    
    begin
        # Install and verify
        fzf_mgr_install "v0.42.0"
        
        # Check binary exists
        if not test -x "$custom_dir/fzf"
            echo "Expected fzf binary at: $custom_dir/fzf"
            echo "Binary not found or not executable"
            echo "Directory contents:"
            ls -la $custom_dir
            echo "Installation directory contents:"
            ls -la $FZF_INSTALL_DIR
            echo "Local bin contents:"
            ls -la $test_temp_dir/local/bin
            return 1
        end
        
        # Add custom dir to PATH and verify version
        set -gx PATH $custom_dir $PATH
        set -l installed_ver (fzf_mgr_get_version)
        if not test "$installed_ver" = "0.42.0"
            echo "Expected version: 0.42.0"
            echo "Actual version: $installed_ver"
            echo "PATH: $PATH"
            echo "FZF binary location: "(which fzf)
            return 1
        end
        return 0
    end
end

# Run all tests
echo "Running fzf manager tests..."
echo "=========================="

set -l failed_tests 0
set -l total_tests 0

# Save original FZF_VERSION
set -l original_fzf_version $FZF_VERSION

# Run tests
for test_pair in "sandbox setup:test_sandbox_setup" \
                 "environment variables:test_env_vars" \
                 "get_version:test_get_version" \
                 "get_latest_version:test_get_latest_version" \
                 "needs_update with current version:test_needs_update_with_current" \
                 "needs_update with different version:test_needs_update_with_different" \
                 "install:test_install" \
                 "auto-update:test_auto_update" \
                 "custom install directory:test_custom_install_dir"
    set total_tests (math $total_tests + 1)
    set -l name (string split ":" $test_pair)[1]
    set -l func (string split ":" $test_pair)[2]
    run_test $name $func
    if test $status -ne 0
        set failed_tests (math $failed_tests + 1)
    end
end

# Restore original FZF_VERSION
set -gx FZF_VERSION $original_fzf_version

echo "=========================="
if test $failed_tests -gt 0
    set_color red
    echo "Test summary: "(math $total_tests - $failed_tests)" passed, $failed_tests failed"
    set_color normal
else
    set_color green
    echo "Test summary: $total_tests passed, 0 failed"
    set_color normal
end

exit $failed_tests 