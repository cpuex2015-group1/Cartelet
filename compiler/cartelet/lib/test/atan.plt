set terminal png font "MigMix 2M,14"
set title "atan"
set xlabel "x"
set ylabel "y"
set output "result.png"
plot "test-atan.out" using 1:2 with points
