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
    
    # Create test bin directories
    mkdir -p $test_temp_dir/bin
    mkdir -p $test_temp_dir/local/bin
    
    # Add both test directories to PATH
    set -gx PATH $test_temp_dir/bin $test_temp_dir/local/bin $PATH
    
    # Save original environment
    set -g original_fzf_version $FZF_VERSION
    set -g original_fish_function_path $fish_function_path
end

function teardown
    # Restore original PATH
    set -gx PATH $original_path
    
    # Restore original environment
    set -gx FZF_VERSION $original_fzf_version
    set -gx fish_function_path $original_fish_function_path
    
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
    
    if eval $test_fn
        set_color green
        echo "PASS"
        set_color normal
        set -l result 0
    else
        set_color red
        echo "FAIL"
        set_color normal
        set -l result 1
    end
    
    # Run teardown after each test
    teardown
    return $result
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
    
    # Mock tar for installation
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/tar
    echo 'echo "#!/usr/bin/env fish" > fzf' >> $test_temp_dir/bin/tar
    echo 'echo "echo \"0.42.0\"" >> fzf' >> $test_temp_dir/bin/tar
    echo 'chmod +x fzf' >> $test_temp_dir/bin/tar
    chmod +x $test_temp_dir/bin/tar
    
    # Enable auto-update
    set -gx FZF_AUTO_UPDATE true
    set -gx FZF_VERSION latest
    
    # Run ensure and verify update
    fzf_mgr_ensure
    set -l new_ver (fzf_mgr_get_version)
    test "$new_ver" = "0.42.0"
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
    echo 'echo "#!/usr/bin/env fish" > fzf' >> $test_temp_dir/bin/tar
    echo 'echo "echo \"0.42.0\"" >> fzf' >> $test_temp_dir/bin/tar
    echo 'chmod +x fzf' >> $test_temp_dir/bin/tar
    chmod +x $test_temp_dir/bin/tar
    
    fzf_mgr_install "v0.42.0"
    test -x "$custom_dir/fzf"
end

# Run all tests
echo "Running fzf manager tests..."
echo "=========================="

set -l failed_tests 0

# Save original FZF_VERSION
set -l original_fzf_version $FZF_VERSION

# Run tests
run_test "get_version" test_get_version; or set failed_tests (math $failed_tests + 1)
run_test "get_latest_version" test_get_latest_version; or set failed_tests (math $failed_tests + 1)
run_test "needs_update with current version" test_needs_update_with_current; or set failed_tests (math $failed_tests + 1)
run_test "needs_update with different version" test_needs_update_with_different; or set failed_tests (math $failed_tests + 1)
run_test "install" test_install; or set failed_tests (math $failed_tests + 1)
run_test "auto-update" test_auto_update; or set failed_tests (math $failed_tests + 1)
run_test "custom install directory" test_custom_install_dir; or set failed_tests (math $failed_tests + 1)

# Restore original FZF_VERSION
set -gx FZF_VERSION $original_fzf_version

echo "=========================="
echo "Test summary: "(math 7 - $failed_tests)" passed, $failed_tests failed"

exit $failed_tests 