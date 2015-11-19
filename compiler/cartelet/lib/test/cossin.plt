set terminal png font "MigMix 2M,14"
set title "sin"
set xlabel "x"
set ylabel "y"
set output "result.png"
plot "test-cos-sin.out" using 1:2 with points
