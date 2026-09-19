# Render every chart in this directory with gnuplot.  "make" draws
# them all with the default color sequence, "make SEQ=podo" with the
# color-blind-safe one, and "make clean" removes the images.
#
# The two "-auto" scripts take the color sequence from the "seq"
# variable and name their output after it.  throughput-5000.gnuplot
# ignores the variable and always writes throughput-5000.png.

SEQ = default
GNUPLOT = gnuplot -e "seq='$(SEQ)'"

CHARTS = throughput-5000.png \
	throughput-crossing-$(SEQ).png \
	throughput-survey-$(SEQ).png

all: $(CHARTS)

throughput-5000.png: throughput-5000.gnuplot throughput-5000.dat
	$(GNUPLOT) throughput-5000.gnuplot

throughput-crossing-$(SEQ).png: throughput-crossing-auto.gnuplot \
		throughput-30000.dat throughput-31000.dat \
		throughput-32000.dat throughput-32000-replicates.dat \
		throughput-35000.dat
	$(GNUPLOT) throughput-crossing-auto.gnuplot

throughput-survey-$(SEQ).png: throughput-survey-auto.gnuplot \
		throughput-5000.dat throughput-30000.dat throughput-31000.dat \
		throughput-32000.dat throughput-35000.dat throughput-45000.dat \
		throughput-97000.dat
	$(GNUPLOT) throughput-survey-auto.gnuplot

clean:
	rm -f $(CHARTS)

.PHONY: all clean
