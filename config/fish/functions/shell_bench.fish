function shell_bench --description 'Compare Fish and Zsh startup times'
    set -l iterations 10
    set -l fish_times
    set -l zsh_times
    set -l max_retries 3

    # Get the time command from PATH
    set -l time_cmd (which time)
    echo "DEBUG: Using time command: $time_cmd"

    echo "Running $iterations iterations for each shell..."
    echo "============================================"
    
    for i in (seq 1 $iterations)
        echo -n "Iteration $i: "
        
        # Benchmark Fish with retries
        set -l fish_time 0
        set -l retry_count 0
        while test "$fish_time" -le 0; and test $retry_count -lt $max_retries
            set -l output ($time_cmd -p fish -i -c exit 2>&1 | grep real | awk '{print $2}')
            if test -n "$output"
                set fish_time (math "round($output * 1000)")
            else
                set fish_time 0
            end
            set retry_count (math $retry_count + 1)
            if test $retry_count -gt 1
                echo -n "Retrying Fish ($retry_count)... "
            end
        end
        # Convert back to seconds
        if test "$fish_time" -gt 0
            set fish_time (math "$fish_time / 1000")
            set -a fish_times $fish_time
        end
        
        # Benchmark Zsh with retries
        set -l zsh_time 0
        set -l retry_count 0
        while test "$zsh_time" -le 0; and test $retry_count -lt $max_retries
            set -l output ($time_cmd -p zsh -i -c exit 2>&1 | grep real | awk '{print $2}')
            if test -n "$output"
                set zsh_time (math "round($output * 1000)")
            else
                set zsh_time 0
            end
            set retry_count (math $retry_count + 1)
            if test $retry_count -gt 1
                echo -n "Retrying Zsh ($retry_count)... "
            end
        end
        # Convert back to seconds
        if test "$zsh_time" -gt 0
            set zsh_time (math "$zsh_time / 1000")
            set -a zsh_times $zsh_time
        end
        
        printf "Fish: %.3fs, Zsh: %.3fs\n" $fish_time $zsh_time
    end

    # Function to calculate median
    function __median
        set -l sorted_nums $argv
        set sorted_nums (string join \n $sorted_nums | sort -n)
        set -l len (count $sorted_nums)
        if test (math "$len % 2") -eq 0
            set -l mid1 (math "$len / 2")
            set -l mid2 (math "$mid1 + 1")
            math "($sorted_nums[$mid1] + $sorted_nums[$mid2]) / 2"
        else
            set -l mid (math "ceil($len / 2)")
            echo $sorted_nums[$mid]
        end
    end

    # Function to calculate mean
    function __mean
        set -l sum 0
        for num in $argv
            set sum (math "$sum + $num")
        end
        if test (count $argv) -gt 0
            math "$sum / "(count $argv)
        else
            echo "0"
        end
    end

    # Function to remove outliers using IQR method
    function __remove_outliers
        set -l nums $argv
        set -l sorted (string join \n $nums | sort -n)
        set -l len (count $sorted)
        set -l q1_idx (math "ceil($len * 0.25)")
        set -l q3_idx (math "ceil($len * 0.75)")
        set -l q1 $sorted[$q1_idx]
        set -l q3 $sorted[$q3_idx]
        set -l iqr (math "$q3 - $q1")
        set -l lower_bound (math "$q1 - 1.5 * $iqr")
        set -l upper_bound (math "$q3 + 1.5 * $iqr")
        
        for num in $nums
            set -l num_int (math "$num * 1000")
            set -l lower_int (math "$lower_bound * 1000")
            set -l upper_int (math "$upper_bound * 1000")
            
            if test $num_int -ge $lower_int
                if test $num_int -le $upper_int
                    echo $num
                end
            end
        end
    end

    # Only proceed if we have valid measurements
    if test (count $fish_times) -eq 0; or test (count $zsh_times) -eq 0
        echo "Error: Failed to get valid measurements after retries"
        return 1
    end

    # Remove outliers and calculate statistics
    set -l clean_fish_times (__remove_outliers $fish_times)
    set -l clean_zsh_times (__remove_outliers $zsh_times)

    # Initialize variables
    set -l avg_fish 0
    set -l avg_zsh 0
    set -l median_fish 0
    set -l median_zsh 0

    # Calculate statistics if we have valid samples
    if test (count $clean_fish_times) -gt 0
        set avg_fish (__mean $clean_fish_times)
        set median_fish (__median $clean_fish_times)
    end

    if test (count $clean_zsh_times) -gt 0
        set avg_zsh (__mean $clean_zsh_times)
        set median_zsh (__median $clean_zsh_times)
    end

    echo "============================================"
    echo "Results after filtering outliers (Fish: "(count $clean_fish_times)", Zsh: "(count $clean_zsh_times)" valid samples):"
    printf "Fish startup time - Mean: %.3fs, Median: %.3fs\n" $avg_fish $median_fish
    printf "Zsh startup time  - Mean: %.3fs, Median: %.3fs\n" $avg_zsh $median_zsh
    
    # Calculate and show difference using medians
    if test (math "round($median_fish * 1000)") -lt (math "round($median_zsh * 1000)")
        set -l diff (math "$median_zsh - $median_fish")
        set -l percent (math "($median_zsh - $median_fish) / $median_zsh * 100")
        printf "Fish is %.3fs faster (%.1f%% improvement)\n" $diff $percent
    else
        set -l diff (math "$median_fish - $median_zsh")
        set -l percent (math "($median_fish - $median_zsh) / $median_fish * 100")
        printf "Zsh is %.3fs faster (%.1f%% improvement)\n" $diff $percent
    end
end 