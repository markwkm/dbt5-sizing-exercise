#!/bin/sh
#
# How hard the Market Exchange's connections to the Brokerage House
# are working in each run, to tell whether the pool is large enough.
#
# Usage: mee-load.sh [RUNDIR ...]
#
# Per run: the Trade Result delivery rate; the mean and 99th
# percentile of the delivery round trip as the Market Exchange logs
# it, which is the Brokerage House's transaction and excludes any wait
# for a connection; the mean number of connections busy, rate times
# mean round trip; the ratio of Trade Results to Trade Orders, which
# falls below its low-load value when deliveries lag; and how far the
# machine's task count rose during the run, which is the number of
# deliveries queued for a connection, since everything else is
# steady.  With no arguments, every reportable run.

. "$(dirname "$0")/env.sh"

analyze()
{
	D="${1}"
	U="$(basename "${D}" | sed 's/^c[0-9]*-u0*//')"
	S="${D}/${U}/summary.rst"
	[ -f "${S}" ] || return
	START="$(awk -F, '$2 == "START" {print $1; exit}' \
			"${D}/${U}/driver/mix-dr.log")"
	SECS="$(awk '/Measurement Interval/ {print $NF * 60}' "${S}")"
	TO="$(awk '$1 == "Trade" && $2 == "Order" && $3 !~ /\./ {print $3}' \
			"${S}")"
	TASKS="$(sadf -d -- -q LOAD "${D}/${U}/db/$(hostname)/sysstat/sar.datafile" \
			2> /dev/null | awk -F';' 'NR > 1 {
				if (min == "" || $5 < min) min = $5
				if ($5 > max) max = $5
			} END { print max - min }')"
	awk -F, -v st="${START}" -v secs="${SECS}" -v to="${TO}" \
			-v u="${U}" -v tasks="${TASKS}" '
	$2 == 9 && $3 == 0 && $1 >= st && $1 < st + secs {
		n++
		sum += $4
		# Histogram in whole milliseconds, for the percentile.
		b = int($4 * 1000)
		hist[b]++
		if (b > top)
			top = b
	}
	END {
		if (n == 0)
			exit
		c = 0
		for (b = 0; b <= top; b++) {
			c += hist[b]
			if (c >= 0.99 * n) {
				p99 = b / 1000
				break
			}
		}
		rate = n / secs
		mean = sum / n
		printf "%5s %8.2f %8.1f %8.1f %6.2f %8.3f %8s\n",
				u, rate, mean * 1000, p99 * 1000, rate * mean,
				n / to, tasks
	}' "${D}/${U}"/mee/mix-me-*.log
}

printf '%5s %8s %8s %8s %6s %8s %8s\n' \
		USERS TR/s MEAN_ms P99_ms BUSY TR/TO TASKS+
if [ "${#}" -eq 0 ]; then
	for D in "${RESULTS}"/c[0-9]*-u[0-9][0-9]; do
		[ -d "${D}" ] && analyze "${D}"
	done
else
	for D in "$@"; do
		analyze "${D}"
	done
fi

exit 0
