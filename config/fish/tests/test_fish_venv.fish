#!/usr/bin/env fish

# Verify we're running in test mode
if not set -q FISH_TEST
    echo "Error: Tests must be run with FISH_TEST environment variable set"
    exit 1
end

# Load required functions
source (status dirname)/../conf.d/fish_venv.fish

# Setup and teardown functions
function setup
    echo "Setting up test environment..." >&2
    # Create a temporary test directory
    set -g test_temp_dir (mktemp -d)
    set -g original_path $PATH
    
    # Create test project structure
    mkdir -p $test_temp_dir/{project1,project2}
    mkdir -p $test_temp_dir/project1/.venv/bin
    mkdir -p $test_temp_dir/project2/venv/bin
    mkdir -p $test_temp_dir/poetry_project/.venv/bin
    
    # Create mock virtualenv activate scripts
    echo "set -gx VIRTUAL_ENV (dirname (dirname (status filename)))" > $test_temp_dir/project1/.venv/bin/activate.fish
    echo "set -gx _OLD_VIRTUAL_PATH \$PATH" >> $test_temp_dir/project1/.venv/bin/activate.fish
    echo "set -gx PATH \"\$VIRTUAL_ENV/bin\" \$PATH" >> $test_temp_dir/project1/.venv/bin/activate.fish
    
    echo "set -gx VIRTUAL_ENV (dirname (dirname (status filename)))" > $test_temp_dir/project2/venv/bin/activate.fish
    echo "set -gx _OLD_VIRTUAL_PATH \$PATH" >> $test_temp_dir/project2/venv/bin/activate.fish
    echo "set -gx PATH \"\$VIRTUAL_ENV/bin\" \$PATH" >> $test_temp_dir/project2/venv/bin/activate.fish
    
    # Create poetry venv activate script
    echo "set -gx VIRTUAL_ENV (dirname (dirname (status filename)))" > $test_temp_dir/poetry_project/.venv/bin/activate.fish
    echo "set -gx _OLD_VIRTUAL_PATH \$PATH" >> $test_temp_dir/poetry_project/.venv/bin/activate.fish
    echo "set -gx PATH \"\$VIRTUAL_ENV/bin\" \$PATH" >> $test_temp_dir/poetry_project/.venv/bin/activate.fish
    
    # Create mock poetry files
    echo "{\"name\": \"test-project\", \"version\": \"0.1.0\"}" > $test_temp_dir/poetry_project/pyproject.toml
    
    # Create mock poetry binary
    mkdir -p $test_temp_dir/bin
    echo '#!/usr/bin/env fish' > $test_temp_dir/bin/poetry
    echo 'switch $argv[1]' >> $test_temp_dir/bin/poetry
    echo '    case "env info -p"' >> $test_temp_dir/bin/poetry
    echo '        echo "$test_temp_dir/poetry_project/.venv"' >> $test_temp_dir/bin/poetry
    echo '    case "shell --quiet --no-ansi"' >> $test_temp_dir/bin/poetry
    echo '        set -gx POETRY_ACTIVE 1' >> $test_temp_dir/bin/poetry
    echo '        source $test_temp_dir/poetry_project/.venv/bin/activate.fish' >> $test_temp_dir/bin/poetry
    echo 'end' >> $test_temp_dir/bin/poetry
    chmod +x $test_temp_dir/bin/poetry
    
    # Save original environment
    set -g original_virtual_env $VIRTUAL_ENV
    set -g original_poetry_active $POETRY_ACTIVE
    set -g original_pwd $PWD
    
    # Add test bin to PATH
    set -gx PATH $test_temp_dir/bin $PATH
    echo "Test environment setup complete" >&2
end

function teardown
    echo "Cleaning up test environment..." >&2
    # Deactivate any active virtualenv
    if functions -q deactivate
        deactivate
    end
    
    # Restore original environment
    set -gx PATH $original_path
    set -gx VIRTUAL_ENV $original_virtual_env
    set -gx POETRY_ACTIVE $original_poetry_active
    cd $original_pwd
    
    # Clean up test directory
    rm -rf $test_temp_dir
    
    # Reset handling flag
    set -g __VENV_HANDLING 0
    echo "Test environment cleanup complete" >&2
end

# Helper function to run a test
function run_test
    set -l test_name $argv[1]
    set -l test_fn $argv[2..-1]
    echo -n "Testing $test_name... "
    
    # Run setup before each test
    setup
    
    # Run the test with a timeout
    fish -c "
        cd $test_temp_dir
        source (status dirname)/test_fish_venv.fish
        $test_fn
    " >/dev/null 2>&1 &
    
    set -l pid $last_pid
    set -l timeout 5
    
    # Wait for the test to complete or timeout
    for i in (seq $timeout)
        if not kill -0 $pid 2>/dev/null
            wait $pid
            set -l test_status $status
            if test $test_status -eq 0
                set_color green
                echo "PASS"
                set_color normal
                teardown
                return 0
            else
                set_color red
                echo "FAIL"
                set_color normal
                teardown
                return 1
            end
        end
        sleep 1
    end
    
    # Kill the test if it timed out
    kill $pid 2>/dev/null
    set_color red
    echo "TIMEOUT"
    set_color normal
    teardown
    return 1
end

# Test virtualenv activation
function test_venv_activation
    cd $test_temp_dir/project1
    __auto_source_venv
    test -n "$VIRTUAL_ENV"; and string match -q "*project1/.venv" "$VIRTUAL_ENV"
end

# Test virtualenv deactivation
function test_venv_deactivation
    # First activate a venv
    cd $test_temp_dir/project1
    __auto_source_venv
    set -l first_venv $VIRTUAL_ENV
    
    # Then move to a directory without venv
    cd $test_temp_dir
    __auto_source_venv
    test -z "$VIRTUAL_ENV"; and test "$first_venv" != "$VIRTUAL_ENV"
end

# Test switching between virtualenvs
function test_venv_switching
    # Activate first venv
    cd $test_temp_dir/project1
    __auto_source_venv
    set -l first_venv $VIRTUAL_ENV
    
    # Switch to second venv
    cd $test_temp_dir/project2
    __auto_source_venv
    set -l second_venv $VIRTUAL_ENV
    
    test "$first_venv" != "$second_venv"; and string match -q "*project2/venv" "$second_venv"
end

# Test poetry integration
function test_poetry_activation
    cd $test_temp_dir/poetry_project
    __poetry_shell_activate
    test -n "$POETRY_ACTIVE"; and test -n "$VIRTUAL_ENV"
end

# Test recursive handling prevention
function test_recursive_handling
    set -g __VENV_HANDLING 1
    cd $test_temp_dir/project1
    __auto_source_venv
    test -z "$VIRTUAL_ENV" # Should not activate due to handling flag
end

# Test safe activation
function test_safe_activation
    cd $test_temp_dir/project1
    set -l old_path $PATH
    __safe_activate_venv "$test_temp_dir/project1/.venv/bin/activate.fish"
    test -n "$VIRTUAL_ENV"; and test "$PATH" != "$old_path"
end

# Run all tests
echo "Running fish_venv tests..."
echo "=========================="

set -l failed_tests 0

# Run tests
for test_name in venv_activation venv_deactivation venv_switching poetry_activation recursive_handling safe_activation
    run_test $test_name test_$test_name
    set failed_tests (math $failed_tests + $status)
end

echo "=========================="
echo "Test summary: "(math 6 - $failed_tests)" passed, $failed_tests failed"

exit $failed_tests 