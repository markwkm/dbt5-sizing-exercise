# Throughput against emulated users for every customer count the
# plan's bisection visits, one line per customer count, with the
# limit each count is judged against under the specification's rule,
# 1.02 times customers / 500, as a dashed line in the same color.
# The limit's value is in the key entry of its series.  Data from
# throughput-<customers>.dat.  Series are ordered and colored in the
# order the bisection visits them: 5000, 97000, 45000, 30000, 35000,
# 31000, 32000.  Colors come from gnuplot's own sequence, chosen with
# the "seq" variable, and a series and its limit line share a color
# by line type index.
#
#     gnuplot -e "seq='podo'" throughput-survey-auto.gnuplot
#     gnuplot -e "seq='default'" throughput-survey-auto.gnuplot

if (!exists("seq")) seq = "podo"
set colorsequence @seq

set terminal pngcairo size 1000,618 font ",11"
set output sprintf("throughput-survey-%s.png", seq)
set title "Throughput vs users, by customer count"
set xlabel "Users"
set ylabel "Throughput (trtps)"
set xrange [0:44]
set yrange [0:245]
set xtics 4
set style line 100 lc rgb "#e6e6e6" lw 1
set grid ls 100
set border lc rgb "#666666"
set key at 43,176 right Right samplen 2 spacing 1.3

ink = "#333333"

# The limit used for every verdict, 1.02 times customers / 500, one
# per series in the series' color.
set arrow 1 from 0,10.2  to 44,10.2  nohead dt 2 lw 1.5 lc 1
set arrow 2 from 0,197.9 to 44,197.9 nohead dt 2 lw 1.5 lc 2
set arrow 3 from 0,91.8  to 44,91.8  nohead dt 2 lw 1.5 lc 3
set arrow 4 from 0,61.2  to 44,61.2  nohead dt 2 lw 1.5 lc 4
set arrow 5 from 0,71.4  to 44,71.4  nohead dt 2 lw 1.5 lc 5
set arrow 6 from 0,63.24 to 44,63.24 nohead dt 2 lw 1.5 lc 6
set arrow 7 from 0,65.28 to 44,65.28 nohead dt 2 lw 1.5 lc 7

# Direct labels where the series are far from any other.
set label 11 "5000"  at 32,183.21 left offset 1,0    tc rgb ink
set label 12 "97000" at 16,1.98   left offset 1,-0.5 tc rgb ink
set label 13 "45000" at 16,4.62   left offset 1,0.9  tc rgb ink

set style data linespoints
plot "throughput-5000.dat"  using 1:2 lw 2 pt 7 ps 1.3 lc 1 \
         title "5000 customers, limit 10.2", \
     "throughput-97000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 2 \
         title "97000 customers, limit 197.9", \
     "throughput-45000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 3 \
         title "45000 customers, limit 91.8", \
     "throughput-30000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 4 \
         title "30000 customers, limit 61.2", \
     "throughput-35000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 5 \
         title "35000 customers, limit 71.4", \
     "throughput-31000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 6 \
         title "31000 customers, limit 63.24", \
     "throughput-32000.dat" using 1:2 lw 2 pt 7 ps 1.3 lc 7 \
         title "32000 customers, limit 65.28"
