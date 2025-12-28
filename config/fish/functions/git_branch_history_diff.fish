function git_branch_history_diff --description 'Show git diff from branch point to HEAD'
    # Get the first remote (usually origin)
    set -l remote (git remote 2>/dev/null | head -n1)
    if test -z "$remote"
        echo "No git remote found"
        return 1
    end

    # Try to get the HEAD branch from remote
    set -l base_branch (git remote show "$remote" 2>/dev/null | awk '/HEAD branch/ {print $NF}')

    # Fallback to main or master if HEAD branch not found
    if test -z "$base_branch"
        for b in main master
            if git show-ref --verify --quiet "refs/remotes/$remote/$b"
                set base_branch $b
                break
            end
        end
    end

    if test -z "$base_branch"
        echo "Could not determine base branch"
        return 1
    end

    git diff --patch "$remote/$base_branch"..HEAD
end
