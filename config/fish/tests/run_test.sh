#!/bin/bash

# Check if a test file was specified
if [ $# -ne 1 ]; then
    echo "Usage: $0 <test_file>"
    echo "Example: $0 test_fish_venv.fish"
    exit 1
fi

# Get the absolute path to the test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="$1"

# Check if the test file exists
if [ ! -f "$TEST_DIR/$TEST_FILE" ]; then
    echo "Error: Test file '$TEST_FILE' not found in $TEST_DIR"
    exit 1
fi

# Run the specified test in fish with debug output and test flag
env FISH_TEST=1 FISH_DEBUG=1 fish --no-config -c "cd '$TEST_DIR' && ./$TEST_FILE" 2>&1 | grep -v "Failed to match debug category" 