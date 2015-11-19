set terminal png font "MigMix 2M,14"
set title "int_of_float"
set xlabel "x"
set ylabel "y"
set output "result.png"
set arrow from 0,-11 to 0,10 nohead lc rgb "forest-green" lw 1
set arrow from 0.5,-11 to 0.5,10 nohead lc rgb "forest-green" lw 1
set arrow from 1,-11 to 1,10 nohead lc rgb "forest-green" lw 1
set arrow from 1.5,-11 to 1.5,10 nohead lc rgb "forest-green" lw 1
set arrow from 2,-11 to 2,10 nohead lc rgb "forest-green" lw 1
set arrow from -0.5,-11 to -0.5,10 nohead lc rgb "forest-green" lw 1
set arrow from -1,-11 to -1,10 nohead lc rgb "forest-green" lw 1
set arrow from -1.5,-11 to -1.5,10 nohead lc rgb "forest-green" lw 1
set arrow from -2,-11 to -2,10 nohead lc rgb "forest-green" lw 1
plot "test-int-float.out" using 1:2 with points, \
     0.0 notitle
