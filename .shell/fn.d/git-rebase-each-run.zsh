git-rebase-each-run() {
  if (( $# < 2 )); then
    echo "Usage: git-rebase-each-run <command> <base-branch>"
    return 1
  fi

  # Get the base branch (last argument)
  local base_branch="${@[-1]}"            # last argument
  # Get all arguments except the last as the command
  local user_cmd="${@[1,-2]}"             # all arguments except last

  git fetch origin
  echo "Rebasing $(git branch --show-current) onto $base_branch..."
  echo "Running '$user_cmd' on each commit."

  # Run rebase with exec
  # Prints commit info, runs the user's command, then stages and amends changes if any
  # Uses && to fail-fast: if any command fails, rebase stops for manual intervention
  # Wraps user_cmd in subshell to handle semicolons and complex commands correctly
  local rebase_script="git log -1 --oneline HEAD && (${user_cmd}) && git add -u && (git diff-index --quiet HEAD -- || git commit --amend --no-edit)"
  
  GIT_SEQUENCE_EDITOR=: git rebase -i -x "$rebase_script" "$base_branch"
}
