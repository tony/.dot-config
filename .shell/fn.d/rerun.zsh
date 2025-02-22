# Usage:
#   rerun <times> [--fail-fast] -- <command> [args...]
#
# Examples:
#   rerun 5 -- echo "Hello"
#   rerun 3 --fail-fast -- my_script.sh arg1 arg2

rerun() {
  # If user requests help explicitly
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat << EOF
Usage: rerun <times> [--fail-fast] -- <command> [args...]
Run a command multiple times in sequence.

Options:
  --fail-fast   Stop reruns immediately after any failure.
  -h, --help    Show this help message and exit.
EOF
    return 0
  fi

  # Must have at least 3 args: <times> [maybe an option] -- <command>
  if (( $# < 3 )); then
    echo "Error: Not enough arguments."
    echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
    return 1
  fi

  # 1) Read how many times to run
  local times=$1
  shift

  # Verify times is a positive integer
  if ! [[ "$times" =~ ^[0-9]+$ ]]; then
    echo "Error: <times> must be a positive integer."
    return 1
  fi
  if (( times == 0 )); then
    echo "Warning: <times> is 0, so command will not run."
    return 0
  fi

  # 2) Optional flags before the double dash
  local fail_fast=0
  while [[ "$1" != "--" ]]; do
    case "$1" in
      --fail-fast)
        fail_fast=1
        shift
        ;;
      *)
        echo "Error: Unknown option '$1'"
        echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
        return 1
        ;;
    esac
  done

  # 3) Remove the '--' delimiter
  shift

  # 4) Capture the command + any arguments in an array
  local cmd=("$@")
  if (( ${#cmd[@]} == 0 )); then
    echo "Error: No command specified after '--'."
    echo "Usage: rerun <times> [--fail-fast] -- <command> [args...]"
    return 1
  fi

  # 5) Run the command <times> times
  local i exit_code=0
  for (( i = 1; i <= times; i++ )); do
    echo "Run #$i: ${cmd[@]}"
    "${cmd[@]}"
    exit_code=$?
    if (( exit_code != 0 )); then
      echo "Command failed on run #$i with exit code $exit_code."
      if (( fail_fast )); then
        break
      fi
    fi
  done

  # Return the exit code of the last run
  return $exit_code
}
