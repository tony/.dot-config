function git-rebase-each-run --description 'Run a command on each commit during git rebase'
    if test (count $argv) -lt 2
        echo "Usage: git-rebase-each-run <command> <base-branch>"
        return 1
    end

    # Get the base branch (last argument)
    set -l base_branch $argv[-1]
    # Get all arguments except the last as the command
    set -l cmd_parts $argv[1..-2]
    # Join command parts with spaces to handle multi-word commands
    set -l user_cmd (string join ' ' $cmd_parts)

    git fetch origin
    echo "Rebasing "(git branch --show-current)" onto $base_branch..."
    echo "Running '$user_cmd' on each commit."

    # Run rebase with exec
    # Prints commit info, runs the user's command, then stages and amends changes if any
    set -l rebase_script "git log -1 --oneline HEAD; $user_cmd; git add -u; git diff-index --quiet HEAD -- || git commit --amend --no-edit"
    
    # Use env to set GIT_SEQUENCE_EDITOR without affecting the shell's environment
    env GIT_SEQUENCE_EDITOR=: git rebase -i -x "$rebase_script" "$base_branch"
end 