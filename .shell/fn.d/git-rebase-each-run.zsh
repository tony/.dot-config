git-rebase-each-run() {
  if (( $# < 2 )); then
    echo "Usage: git-rebase-each-run <command> <base-branch>"
    return 1
  fi

  # Get the base branch (last argument)
  local base_branch="${@[-1]}"            # last argument
  # Get all arguments except the last as the command
  local user_cmd="${@[1,-2]}"             # all arguments except last

  # Resolve the absolute repo root now, before the rebase sequence starts.
  # git rev-parse --show-toplevel works correctly in both main checkouts and
  # linked worktrees. In a linked worktree, .git is a file (not a directory)
  # pointing back to the main repo's .git/worktrees/<name>. Some tools — most
  # notably Yarn v1 — walk up the directory tree looking for a package.json
  # with "workspaces" and use .git-as-directory as a root boundary. When .git
  # is a file they overshoot and report "Cannot find the root of your
  # workspace". Pinning CWD to the resolved root at the start of each exec
  # step sidesteps all such tool-specific heuristic failures.
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    print -u2 "fatal: not inside a git repository"
    return 1
  }

  git fetch origin
  echo "Rebasing $(git branch --show-current) onto $base_branch..."
  echo "Running '$user_cmd' on each commit."

  # Run rebase with exec
  # Prints commit info, runs the user's command, then stages and amends changes if any
  # Uses && to fail-fast: if any command fails, rebase stops for manual intervention
  # Wraps user_cmd in subshell to handle semicolons and complex commands correctly
  # ${(q)git_root} single-quotes the path, safe for paths containing spaces.
  local rebase_script="cd ${(q)git_root} && git log -1 --oneline HEAD && (${user_cmd}) && git add -u && (git diff-index --quiet HEAD -- || git commit --amend --no-edit)"

  GIT_SEQUENCE_EDITOR=: git rebase -i -x "$rebase_script" "$base_branch"
}
