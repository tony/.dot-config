function bench --description 'Benchmark fish shell startup time'
    for i in (seq 1 10)
        command time fish -i -c exit
    end
end 