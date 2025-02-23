#!/usr/bin/env fish

# Verify we're running in test mode
if not set -q FISH_TEST
    echo "Error: Tests must be run with FISH_TEST environment variable set"
    exit 1
end

# Load required functions
functions -q shell_bench; or source (status dirname)/../functions/shell_bench.fish

# Setup and teardown functions
function setup
    # Create a temporary test directory
    set -g test_temp_dir (mktemp -d)
    set -g original_path $PATH
    set -g original_function_path $fish_function_path
    
    # Create test bin directories
    mkdir -p $test_temp_dir/usr/bin
    
    # Save original environment
    set -g original_pwd $PWD
    
    # Add function directory to function path
    set -gx fish_function_path (status dirname)/../functions $fish_function_path
    
    # Source shell_bench function to ensure it's available
    source (status dirname)/../functions/shell_bench.fish
    
    # Create mock time command for consistent results
    echo '#!/usr/bin/env fish' > $test_temp_dir/usr/bin/time
    echo 'if test "$argv[1]" = "-p"' >> $test_temp_dir/usr/bin/time
    echo '    switch "$argv[2..-1]"' >> $test_temp_dir/usr/bin/time
    echo '        case "fish *"' >> $test_temp_dir/usr/bin/time
    echo '            echo "real 0.321"' >> $test_temp_dir/usr/bin/time
    echo '            echo "user 0.000"' >> $test_temp_dir/usr/bin/time
    echo '            echo "sys 0.000"' >> $test_temp_dir/usr/bin/time
    echo '        case "zsh *"' >> $test_temp_dir/usr/bin/time
    echo '            if test (random) -lt 15000' >> $test_temp_dir/usr/bin/time
    echo '                # Simulate occasional anomaly' >> $test_temp_dir/usr/bin/time
    echo '                echo "real -2.880"' >> $test_temp_dir/usr/bin/time
    echo '                echo "user 0.000"' >> $test_temp_dir/usr/bin/time
    echo '                echo "sys 0.000"' >> $test_temp_dir/usr/bin/time
    echo '            else' >> $test_temp_dir/usr/bin/time
    echo '                echo "real 0.742"' >> $test_temp_dir/usr/bin/time
    echo '                echo "user 0.000"' >> $test_temp_dir/usr/bin/time
    echo '                echo "sys 0.000"' >> $test_temp_dir/usr/bin/time
    echo '            end' >> $test_temp_dir/usr/bin/time
    echo '    end' >> $test_temp_dir/usr/bin/time
    echo 'end' >> $test_temp_dir/usr/bin/time
    chmod +x $test_temp_dir/usr/bin/time
    
    # Add test bin to PATH (before system paths)
    set -gx PATH $test_temp_dir/usr/bin $PATH
end

function teardown
    # Restore original environment
    set -gx PATH $original_path
    set -gx fish_function_path $original_function_path
    cd $original_pwd
    
    # Clean up test directory
    rm -rf $test_temp_dir
    
    # Clean up global variables
    set -e test_temp_dir
    set -e original_path
    set -e original_pwd
    set -e original_function_path
    set -e __OUTLIER_COUNT
    set -e __RETRY_COUNT_FISH
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
    
    # Test that bin directory exists
    test -d "$test_temp_dir/usr/bin"; or begin
        echo "Test bin directory not created"
        return 1
    end
    
    # Test PATH setup
    set -l first_path (string split : $PATH)[1]
    test "$first_path" = "$test_temp_dir/usr/bin"; or begin
        echo "Expected first PATH entry: $test_temp_dir/usr/bin"
        echo "Actual first PATH entry: $first_path"
        return 1
    end
    
    # Test that mock time command exists and is executable
    test -x "$test_temp_dir/usr/bin/time"; or begin
        echo "Mock time command not created or not executable"
        return 1
    end
    
    return 0
end

# Test basic shell benchmarking
function test_basic_benchmark
    # Run benchmark
    set -l output (shell_bench)
    set -l status_code $status
    
    # Check status code
    if test $status_code -ne 0
        echo "shell_bench failed with status $status_code"
        return 1
    end
    
    # Check output contains expected sections
    string match -q "*Running 10 iterations*" $output; or begin
        echo "Missing iterations header"
        return 1
    end
    
    string match -q "*Results after filtering outliers*" $output; or begin
        echo "Missing results section"
        return 1
    end
    
    string match -q "*Fish startup time*" $output; or begin
        echo "Missing Fish timing results"
        return 1
    end
    
    string match -q "*Zsh startup time*" $output; or begin
        echo "Missing Zsh timing results"
        return 1
    end
    
    return 0
end

# Test outlier handling
function test_outlier_handling
    echo "DEBUG: Starting outlier handling test"
    # Source shell_bench function to ensure it's available
    source (status dirname)/../functions/shell_bench.fish
    
    # Create a function to extract numeric values from output
    function __extract_numbers
        string match -r 'Mean: ([0-9.]+)s' $argv | string replace -r 'Mean: ([0-9.]+)s' '$1'
    end
    
    echo "DEBUG: Running shell_bench..."
    set -l output (shell_bench | string collect)
    echo "DEBUG: shell_bench output:"
    echo $output
    
    echo "DEBUG: Checking for outliers..."
    # Check that we got some outliers removed
    set -l counts (string match -r 'Results after filtering outliers \(Fish: ([0-9]+), Zsh: ([0-9]+) valid samples\)' $output)
    echo "DEBUG: Found "(count $counts)" matches for outlier counts"
    echo "DEBUG: Counts array: $counts"
    
    if test (count $counts) -eq 3
        set -l fish_count $counts[2]
        set -l zsh_count $counts[3]
        echo "DEBUG: Fish count: $fish_count, Zsh count: $zsh_count"
        
        if test "$fish_count" = "10" -a "$zsh_count" = "10"
            echo "Expected some outliers to be removed, but got all samples"
            echo "Got output:"
            echo $output
            return 1
        end
    else
        echo "Could not extract sample counts"
        echo "Got output:"
        echo $output
        return 1
    end
    
    echo "DEBUG: Extracting means..."
    # Extract means to verify they're reasonable
    set -l fish_mean (string match -r 'Fish startup time - Mean: ([0-9.]+)s' $output)[2]
    set -l zsh_mean (string match -r 'Zsh startup time - Mean: ([0-9.]+)s' $output)[2]
    echo "DEBUG: Fish mean: $fish_mean, Zsh mean: $zsh_mean"
    
    echo "DEBUG: Checking mean ranges..."
    # Check that means are within expected ranges
    if begin
        set -l fish_mean_ms (math "round($fish_mean * 1000)")
        test "$fish_mean_ms" -lt (math "round(0.316 * 1000)"); or test "$fish_mean_ms" -gt (math "round(0.326 * 1000)")
    end
        echo "Incorrect Fish mean"
        echo "Expected: 0.321s ±0.005s"
        echo "Got: $fish_mean"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    if begin
        set -l zsh_mean_ms (math "round($zsh_mean * 1000)")
        test "$zsh_mean_ms" -lt (math "round(0.737 * 1000)"); or test "$zsh_mean_ms" -gt (math "round(0.747 * 1000)")
    end
        echo "Incorrect Zsh mean"
        echo "Expected: 0.742s ±0.005s"
        echo "Got: $zsh_mean"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    return 0
end

# Test retry mechanism
function test_retry_mechanism
    # Source shell_bench function to ensure it's available
    source (status dirname)/../functions/shell_bench.fish
    
    # Run benchmark and check output
    set -l output (shell_bench | string collect)
    
    # Check for retry attempts in the output
    if not string match -q "*Retrying*" $output
        echo "No retry attempts detected in output"
        echo "Got output:"
        echo $output
        return 1
    end
    
    return 0
end

# Test statistics calculations
function test_statistics_calculations
    echo "DEBUG: Starting statistics calculations test"
    # Source shell_bench function to ensure it's available
    source (status dirname)/../functions/shell_bench.fish
    
    echo "DEBUG: Running shell_bench..."
    # Run benchmark and check output
    set -l output (shell_bench | string collect)
    echo "DEBUG: shell_bench output:"
    echo $output
    
    echo "DEBUG: Extracting statistics..."
    # Extract means and medians
    set -l fish_mean (string match -r 'Fish startup time - Mean: ([0-9.]+)s' $output)[2]
    set -l fish_median (string match -r 'Fish startup time - Mean: [0-9.]+s, Median: ([0-9.]+)s' $output)[2]
    set -l zsh_mean (string match -r 'Zsh startup time  - Mean: ([0-9.]+)s' $output)[2]
    set -l zsh_median (string match -r 'Zsh startup time  - Mean: [0-9.]+s, Median: ([0-9.]+)s' $output)[2]
    echo "DEBUG: Fish mean: $fish_mean, Fish median: $fish_median"
    echo "DEBUG: Zsh mean: $zsh_mean, Zsh median: $zsh_median"
    
    echo "DEBUG: Checking mean ranges..."
    # Check that means are within expected ranges
    if begin
        set -l fish_mean_ms (math "round($fish_mean * 1000)")
        test "$fish_mean_ms" -lt (math "round(0.316 * 1000)"); or test "$fish_mean_ms" -gt (math "round(0.326 * 1000)")
    end
        echo "Incorrect Fish mean"
        echo "Expected: 0.321s ±0.005s"
        echo "Got: $fish_mean"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    if begin
        set -l zsh_mean_ms (math "round($zsh_mean * 1000)")
        test "$zsh_mean_ms" -lt (math "round(0.737 * 1000)"); or test "$zsh_mean_ms" -gt (math "round(0.747 * 1000)")
    end
        echo "Incorrect Zsh mean"
        echo "Expected: 0.742s ±0.005s"
        echo "Got: $zsh_mean"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    echo "DEBUG: Checking median ranges..."
    # Check that medians are within expected ranges
    if begin
        set -l fish_median_ms (math "round($fish_median * 1000)")
        test $fish_median_ms -lt (math "round(0.316 * 1000)"); or test $fish_median_ms -gt (math "round(0.326 * 1000)")
    end
        echo "Incorrect Fish median"
        echo "Expected: 0.321s ±0.005s"
        echo "Got: $fish_median"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    if begin
        set -l zsh_median_ms (math "round($zsh_median * 1000)")
        test $zsh_median_ms -lt (math "round(0.737 * 1000)"); or test $zsh_median_ms -gt (math "round(0.747 * 1000)")
    end
        echo "Incorrect Zsh median"
        echo "Expected: 0.742s ±0.005s"
        echo "Got: $zsh_median"s
        echo "Full output:"
        echo $output
        return 1
    end
    
    return 0
end

# Run all tests
echo "Running shell_bench tests..."
echo "==========================="

set -l failed_tests 0
set -l total_tests 0

# Run tests
for test_pair in "sandbox setup:test_sandbox_setup" \
                 "basic benchmark:test_basic_benchmark" \
                 "outlier handling:test_outlier_handling" \
                 "retry mechanism:test_retry_mechanism" \
                 "statistics calculations:test_statistics_calculations"
    set total_tests (math $total_tests + 1)
    set -l name (string split ":" $test_pair)[1]
    set -l func (string split ":" $test_pair)[2]
    run_test $name $func
    if test $status -ne 0
        set failed_tests (math $failed_tests + 1)
    end
end

echo "==========================="
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