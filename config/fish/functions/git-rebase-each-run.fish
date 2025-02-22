function git-rebase-each-run --description 'Run a command on each commit during git rebase'
    if test (count $argv) -lt 2
        echo "Usage: git-rebase-each-run <command> <base-branch>"
        return 1
    end

    # Get the base branch (last argument)
    set -l base_branch $argv[-1]
    # Get the command (all arguments except the last)
    set -l user_cmd $argv[1..-2]

    git fetch origin
    echo "Rebasing "(git branch --show-current)" onto $base_branch..."
    echo "Running '$user_cmd' on each commit."

    # Run rebase with exec
    # Prints commit info, runs the user's command, then stages and amends changes if any
    set -l rebase_script "git log -1 --oneline HEAD; $user_cmd; git add -u; git diff-index --quiet HEAD -- || git commit --amend --no-edit"
    
    env GIT_SEQUENCE_EDITOR=: git rebase -i -x "$rebase_script" "$base_branch"
end 