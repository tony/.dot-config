#!/usr/bin/env fish

# Verify we're running in test mode
if not set -q FISH_TEST
    echo "Error: Tests must be run with FISH_TEST environment variable set"
    exit 1
end

# Enable debug output if FISH_DEBUG is set
if set -q FISH_DEBUG
    # Only enable function tracing if explicitly requested
    if test "$FISH_DEBUG" = "trace"
        set fish_trace 1
    end
end

# Get the absolute path to the test directory
set -l test_dir (realpath (dirname (status filename)))
set -l func_dir (realpath $test_dir/../functions)

# Add our function directory to the function path
set -l original_function_path $fish_function_path
set -gx fish_function_path $func_dir $fish_function_path

# Run the tests from the test directory
pushd $test_dir
./test_fzf_mgr.fish
set -l status_code $status

# Restore original function path
set -gx fish_function_path $original_function_path

popd
exit $status_code 