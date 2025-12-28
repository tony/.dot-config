function deep_reset_git_repos --description 'Hard reset all git repos in current directory'
    for dir in */
        if test -d "$dir/.git"
            echo "Processing $dir"
            pushd "$dir"
            git clean -fdx
            git reset --hard
            popd
        end
    end
end
