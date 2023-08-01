set terminal pngcairo enhanced font "arial,10" fontscale 1.0 size 300, 200 
set output 'histogram.png'
set style data histogram 
set style fill solid 
set xtics rotate by -30
set tics front
plot '/dev/stdin' using ($1 == 0 ? NaN : $2):1  notitle w boxes lc 'gray'

