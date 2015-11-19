set terminal png font "MigMix 2M,14"
set title "floor"
set xlabel "x"
set ylabel "y"
set output "result.png"
set arrow from 0,-11 to 0,10 nohead lc rgb "forest-green" lw 1
plot "test-floor.out" using 1:2 with points, \
     0.0 notitle
