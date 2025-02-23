#!/bin/bash

# Get the absolute path to the test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run tests in fish with debug output and test flag
env FISH_TEST=1 FISH_DEBUG=1 fish --no-config -c "cd '$TEST_DIR' && ./run_tests.fish" 2>&1 | grep -v "Failed to match debug category" 