# Throughput against emulated users for the customer counts around
# the crossing, 30000 to 35000, with the limit each count is judged
# against under the specification's rule, 1.02 times customers /
# 500, as a dashed line in the same color.  A detail of
# throughput-survey-auto.gnuplot: the same data files, and the same
# color for each customer count, by line type index, so the two
# charts can be read side by side.  The two replicate runs of the
# answer point are drawn as open circles.
#
#     gnuplot -e "seq='podo'" throughput-crossing-auto.gnuplot
#     gnuplot -e "seq='default'" throughput-crossing-auto.gnuplot

if (!exists("seq")) seq = "podo"
set colorsequence @seq

set terminal pngcairo size 1000,618 font ",11"
set output sprintf("throughput-crossing-%s.png", seq)
set title "Throughput vs users near the crossing, 30000 to 35000 customers"
set xlabel "Users"
set ylabel "Throughput (trtps)"
set xrange [14:42]
set yrange [44:74]
set xtics 2
set ytics 2
set style line 100 lc rgb "#e6e6e6" lw 1
set grid ls 100
set border lc rgb "#666666"
set key at 41.5,58 right Right samplen 2 spacing 1.3

ink = "#333333"

# The limit used for every verdict, 1.02 times customers / 500, one
# per series in the series' color.
set arrow 4 from 14,61.2  to 42,61.2  nohead dt 2 lw 1.5 lc 4
set arrow 5 from 14,71.4  to 42,71.4  nohead dt 2 lw 1.5 lc 5
set arrow 6 from 14,63.24 to 42,63.24 nohead dt 2 lw 1.5 lc 6
set arrow 7 from 14,65.28 to 42,65.28 nohead dt 2 lw 1.5 lc 7
set label 4 "limit, 30000: 61.2"   at 41.7,61.2  right offset 0,-0.7 tc rgb ink font ",9"
set label 5 "limit, 35000: 71.4"   at 41.7,71.4  right offset 0,0.7  tc rgb ink font ",9"
set label 6 "limit, 31000: 63.24"  at 41.7,63.24 right offset 0,-0.7 tc rgb ink font ",9"
set label 7 "limit, 32000: 65.28"  at 41.7,65.28 right offset 0,0.7  tc rgb ink font ",9"

# Direct labels at the right end of each series.
set label 14 "30000" at 40,67.56 left offset 0.7,0 tc rgb ink
set label 15 "35000" at 32,48.30 left offset 0.7,0 tc rgb ink
set label 16 "31000" at 26,65.42 left offset 0.7,0 tc rgb ink
set label 17 "32000" at 32,63.70 left offset 0.7,0 tc rgb ink

set style data linespoints
plot "throughput-30000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 4 \
         title "30000 customers", \
     "throughput-35000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 5 \
         title "35000 customers", \
     "throughput-31000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 6 \
         title "31000 customers", \
     "throughput-32000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 7 \
         title "32000 customers", \
     "throughput-32000-replicates.dat" using 1:2 with points pt 6 ps 1.6 lw 2 lc 7 \
         title "32000, replicates at 18 users"
