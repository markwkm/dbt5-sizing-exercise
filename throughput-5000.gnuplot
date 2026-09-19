# Bar chart of reported throughput against emulated users at 5000
# customers, from throughput-5000.dat.  gnuplot defaults apart from
# the histogram style and solid fill that bars need.
#
#     gnuplot throughput-5000.gnuplot
# Golden ratio aspect, 1000 by 618.
set terminal pngcairo size 1000,618
set output "throughput-5000.png"
set title "Throughput with 5000 customers"
set xlabel "Users"
set ylabel "Throughput (trtps)"
set style data histogram
set style fill solid
plot "throughput-5000.dat" using 2:xtic(1) notitle
