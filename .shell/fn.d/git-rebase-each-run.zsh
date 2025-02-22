git-rebase-each-run() {
  if (( $# < 2 )); then
    echo "Usage: git-rebase-each-run <command> <base-branch>"
    return 1
  fi

  # Combine all arguments except the last into the command (to allow spaces in command)
  local base_branch="${@[ -1 ]}"            # last argument
  local user_cmd="${*:1:$#-1}"              # all arguments except last

  git fetch origin
  echo "Rebasing $(git branch --show-current) onto $base_branch..."
  echo "Running '$user_cmd' on each commit."

  # Run rebase with exec, similar to the Ruff example
  # Prints commit info, runs the user's command, then stages and amends changes if any.
  GIT_SEQUENCE_EDITOR=: git rebase -i -x "git log -1 --oneline HEAD; \
    ${user_cmd}; \
    git add -u; \
    git diff-index --quiet HEAD -- || git commit --amend --no-edit" \
    "$base_branch"
}
