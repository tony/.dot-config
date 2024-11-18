rerun() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: rerun <n> -- <command>"
    return 1
  fi

  local n=$1
  shift

  if [[ $1 != "--" ]]; then
    echo "Usage: rerun <n> -- <command>"
    return 1
  fi
  shift

  local cmd=("$@")

  for i in $(seq 1 $n); do
    echo "Run #$i"
    "${cmd[@]}"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      echo "Command failed on run #$i"
      break
    fi
  done
}

export rerun
