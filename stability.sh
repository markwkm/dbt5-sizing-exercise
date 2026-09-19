#!/bin/sh
#
# Assess whether a test run's Trade Result rate was stable.
#
# Usage: stability.sh RUNDIR [RUNDIR ...]
#        stability.sh --all
#
# RUNDIR is a directory holding driver/ and mee/, for example
# c30000-u20/20.  With --all, every such directory under ${RESULTS}.
#
# Trade Result is transaction type 9 and is recorded by the Market
# Exchange, so the data comes from mee/mix-me-*.log.  The measurement
# clock starts at the START record in driver/mix-dr.log.

. "$(dirname "$0")/env.sh"

BIN="${BIN:-60}"			# seconds per sample
PERIODIC_BIN="${PERIODIC_BIN:-300}"	# bin length for the second reading
SETTLE=0.95	# fraction of steady rate that counts as warmed up

# Assess one run on bins of a given length.  A label, when given,
# replaces "stable" in the verdict.
analyze_bin()
{
	DIR="${1}"
	BIN="${2}"
	LABEL="${3}"
	NAME="$(echo "${DIR}" | sed "s|^${RESULTS}/||")"

	START="$(awk -F, '$2 == "START" {print $1; exit}' \
			"${DIR}/driver/mix-dr.log" 2> /dev/null)"
	if [ -z "${START}" ]; then
		printf '%-22s  no-start\n' "${NAME}"
		return
	fi

	REPORTED="$(awk '/Reported Throughput/ {print $3}' \
			"${DIR}/summary.rst" 2> /dev/null)"

	# shellcheck disable=SC2086
	awk -F, -v st="${START}" -v bin="${BIN}" -v settle="${SETTLE}" \
			-v name="${NAME}" -v reported="${REPORTED}" \
			-v label="${LABEL}" '
	$2 == 9 {
		b = int(($1 - st) / bin)
		if (b < 0)
			b = -1			# before the measurement clock
		count[b]++
		if (b > last)
			last = b
		next
	}
	END {
		# Drop the final bin: it is almost never a whole interval.
		last--
		if (last < 6) {
			printf "%-22s  too-short\n", name
			exit
		}

		n = 0
		for (i = 0; i <= last; i++)
			rate[n++] = count[i] / bin

		# Reference rate from the back half, which is settled by
		# construction, then find where the run first reaches it.
		ref = 0
		half = int(n / 2)
		for (i = half; i < n; i++)
			ref += rate[i]
		ref /= (n - half)

		# Settled means inside a band around the reference, not merely
		# above it.  A run often opens with a burst as the pending
		# trades left by the load are drained, and testing only the
		# lower bound would accept that burst as steady state.
		# The band must be wider than the counting noise, or a slow
		# workload never appears to settle: at a few trtps per second
		# a one minute bin scatters by several percent on its own.
		band = 1 - settle
		noise = 2 / sqrt(ref * bin)
		if (noise > band)
			band = noise
		lo = ref * (1 - band)
		hi = ref * (1 + band)
		ramp = 0
		for (i = 0; i < n; i++) {
			if (rate[i] >= lo && rate[i] <= hi) {
				ok = 1
				for (j = i; j < i + 6 && j < n; j++)
					if (rate[j] < lo || rate[j] > hi)
						ok = 0
				if (ok) {
					ramp = i
					break
				}
			}
		}

		# Statistics over the settled portion only, which must be
		# at least ten minutes and at least six bins.
		minbins = int(600 / bin)
		if (minbins < 6)
			minbins = 6
		if (n - ramp < minbins) {
			printf "%-22s %7s %7s %7s %7s %7s %5.0fs  %s\n",
					name, reported, "-", "-", "-", "-",
					ramp * bin, "never-settled"
			exit
		}

		m = 0; s = 0; k = 0
		for (i = ramp; i < n; i++) {
			m += rate[i]
			k++
		}
		m /= k
		for (i = ramp; i < n; i++)
			s += (rate[i] - m) ^ 2
		sd = sqrt(s / k)
		cv = 100 * sd / m

		# Counting alone puts a floor under the variation: a bin holds
		# about m*bin arrivals, so even a perfectly steady system
		# scatters by 100/sqrt(m*bin) percent.  What matters is how
		# much of the observed scatter is left once that is removed.
		pois = 100 / sqrt(m * bin)
		ex = cv * cv - pois * pois
		excess = (ex > 0) ? sqrt(ex) : 0

		# Least squares slope over the settled portion, as percent of
		# the mean per hour.
		sx = 0; sy = 0; sxx = 0; sxy = 0
		for (i = ramp; i < n; i++) {
			x = i - ramp
			sx += x; sy += rate[i]
			sxx += x * x; sxy += x * rate[i]
		}
		slope = (k * sxy - sx * sy) / (k * sxx - sx * sx)
		drift = 100 * slope * (3600 / bin) / m

		# Excursions beyond three standard deviations.
		spikes = 0
		for (i = ramp; i < n; i++)
			if ((rate[i] - m) > 3 * sd || (m - rate[i]) > 3 * sd)
				spikes++

		verdict = "stable"
		if (excess > 7)
			verdict = "unstable"
		else if (excess > 3)
			verdict = "variable"
		if (drift > 5 || drift < -5)
			verdict = verdict ",drifting"
		if (spikes > n / 20)
			verdict = verdict ",spiky"
		if (label != "" && verdict ~ /^stable/)
			sub(/^stable/, label, verdict)

		printf "%-22s %7s %7.2f %6.1f%% %6.1f%% %6.1f%% %5.0fs  %s\n",
				name, reported, m, cv, pois, drift,
				ramp * bin, verdict
	}' "${DIR}"/mee/mix-me-*.log
}

# Assess one run on one minute bins.  Scatter with a period of a few
# minutes, such as the page cache aging seen from 32000 customers
# up, keeps six consecutive minutes from staying inside the band, so
# such a run reads as unstable or never settled although its rate
# over any five minutes is steady.  When that happens, judge the run
# again on bins longer than the period, and report that reading,
# labeled periodic, when it is stable on those bins.  A run whose
# scatter is counting noise does not become stable on longer bins,
# and keeps its one minute verdict.
analyze()
{
	LINE="$(analyze_bin "${1}" "${BIN}" "")"
	case "${LINE}" in
	(*never-settled|*unstable*)
		AGAIN="$(analyze_bin "${1}" "${PERIODIC_BIN}" periodic)"
		case "${AGAIN}" in
		(*"  periodic"|*"  periodic,"*) LINE="${AGAIN}" ;;
		esac
		;;
	esac
	printf '%s\n' "${LINE}"
}

printf '%-22s %7s %7s %7s %7s %7s %6s  %s\n' \
		RUN REPORTED STEADY CV NOISE DRIFT/H RAMP VERDICT

if [ "${1}" = "--all" ]; then
	find "${RESULTS}" -mindepth 3 -maxdepth 3 -type d -name mee \
			2> /dev/null | sed 's|/mee$||' | sort -V |
	while IFS= read -r D; do
		case "${D}" in
		(*.invalid*) continue ;;
		esac
		analyze "${D}"
	done
else
	for D in "$@"; do
		analyze "${D}"
	done
fi
