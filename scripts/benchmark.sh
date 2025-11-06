start=$(date +%s.%N)

zig build
zig-out/bin/zython example/while.py

end=$(date +%s.%N)
duration=$(echo "$end - $start" | bc)

printf "%.3f seconds\n" "$duration"
