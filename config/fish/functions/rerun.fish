function rerun --description 'Run a command multiple times in sequence'
    # Handle help request
    if contains -- -h $argv; or contains -- --help $argv
        echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
        echo "Run a command multiple times in sequence."
        echo
        echo "Options:"
        echo "  --fail-fast   Stop reruns immediately after any failure."
        echo "  -h, --help    Show this help message and exit."
        return 0
    end

    # Check minimum arguments
    if test (count $argv) -lt 3
        echo "Error: Not enough arguments."
        echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
        return 1
    end

    # Get number of times to run
    set -l times $argv[1]
    set -e argv[1]

    # Verify times is a positive integer
    if not string match -qr '^[0-9]+$' $times
        echo "Error: <times> must be a positive integer."
        return 1
    end
    if test $times -eq 0
        echo "Warning: <times> is 0, so command will not run."
        return 0
    end

    # Parse options before --
    set -l fail_fast 0
    while test (count $argv) -gt 0
        switch $argv[1]
            case --fail-fast
                set fail_fast 1
                set -e argv[1]
            case --
                set -e argv[1]
                break
            case '*'
                echo "Error: Unknown option '$argv[1]'"
                echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
                return 1
        end
    end

    # Check if we have a command after --
    if test (count $argv) -eq 0
        echo "Error: No command specified after '--'."
        echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
        return 1
    end

    # Run the command specified number of times
    set -l exit_code 0
    for i in (seq 1 $times)
        echo "Run #$i: $argv"
        eval $argv
        set exit_code $status
        if test $exit_code -ne 0
            echo "Command failed on run #$i with exit code $exit_code."
            if test $fail_fast -eq 1
                break
            end
        end
    end

    return $exit_code
end 