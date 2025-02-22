function shell_bench --description 'Compare Fish and Zsh startup times'
    set -l iterations 10
    set -l total_fish 0
    set -l total_zsh 0

    echo "Running $iterations iterations for each shell..."
    echo "============================================"
    
    for i in (seq 1 $iterations)
        echo -n "Iteration $i: "
        
        # Benchmark Fish
        set -l fish_time (/usr/bin/time -p fish -i -c exit 2>&1 | grep real | awk '{print $2}')
        set total_fish (math "$total_fish + $fish_time")
        
        # Benchmark Zsh
        set -l zsh_time (/usr/bin/time -p zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
        set total_zsh (math "$total_zsh + $zsh_time")
        
        printf "Fish: %.3fs, Zsh: %.3fs\n" $fish_time $zsh_time
    end

    # Calculate averages
    set -l avg_fish (math "$total_fish / $iterations")
    set -l avg_zsh (math "$total_zsh / $iterations")

    echo "============================================"
    echo "Results after $iterations iterations:"
    printf "Average Fish startup time: %.3fs\n" $avg_fish
    printf "Average Zsh startup time:  %.3fs\n" $avg_zsh
    
    # Calculate and show difference
    if test (math "round($avg_fish * 1000)") -lt (math "round($avg_zsh * 1000)")
        set -l diff (math "$avg_zsh - $avg_fish")
        set -l percent (math "($avg_zsh - $avg_fish) / $avg_zsh * 100")
        printf "Fish is %.3fs faster (%.1f%% improvement)\n" $diff $percent
    else
        set -l diff (math "$avg_fish - $avg_zsh")
        set -l percent (math "($avg_fish - $avg_zsh) / $avg_fish * 100")
        printf "Zsh is %.3fs faster (%.1f%% improvement)\n" $diff $percent
    end
end 