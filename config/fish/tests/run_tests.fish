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

# Initialize test counters
set -l total_tests 0
set -l failed_tests 0

echo "Discovering test files..."
echo "========================"

# Find all test files (test_*.fish)
for test_file in test_*.fish
    # Skip if not a file
    if not test -f $test_file
        continue
    end
    
    set total_tests (math $total_tests + 1)
    echo "Running tests from $test_file..."
    
    # Run the test file
    ./$test_file
    set -l test_status $status
    
    if test $test_status -ne 0
        set failed_tests (math $failed_tests + 1)
        echo "❌ $test_file failed with status $test_status"
    else
        echo "✓ $test_file passed"
    end
    echo
end

# Restore original function path
set -gx fish_function_path $original_function_path

echo "========================"
echo "Test Summary"
echo "------------"
echo "Total test files: $total_tests"
echo "Failed: $failed_tests"
echo "Passed: "(math $total_tests - $failed_tests)

popd
exit $failed_tests 