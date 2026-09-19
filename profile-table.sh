#!/bin/sh
#
# Tabulate the perf profiles of a set of runs side by side, as
# reStructuredText tables for RESULTS.rst: the share of samples by
# component, then the PostgreSQL backend symbols and the kernel
# symbols that took the most processor time, ranked by their largest
# share in any of the runs.
#
# Usage: profile-table.sh RUNDIR [RUNDIR ...]
#
# RUNDIR is a run directory such as c5000-u16; its profile is
# <RUNDIR>/<users>/db/<host>/profile/perf-report.txt.  perf samples
# time on the processor, so these are the most sampled symbols, not
# the most called.  Percentages are of all samples in the run's 20
# second profile, idle included.

. "$(dirname "$0")/env.sh"

TOP="${TOP:-10}"

rst_table()
{
	awk '
	{
		nr = NR
		for (i = 1; i <= NF; i++) {
			cell[nr, i] = $i
			if (length($i) > w[i])
				w[i] = length($i)
			if (nr > 1 && $i !~ /^(-|-?[0-9.]+%?s?)$/)
				text[i] = 1
		}
		if (NF > nf)
			nf = NF
	}
	END {
		for (i = 1; i <= nf; i++) {
			rule = rule (i > 1 ? "  " : "")
			for (j = 0; j < w[i]; j++)
				rule = rule "="
		}
		print rule
		for (r = 1; r <= nr; r++) {
			line = ""
			for (i = 1; i <= nf; i++) {
				if (text[i])
					line = line sprintf("%-" w[i] "s", cell[r, i])
				else
					line = line sprintf("%" w[i] "s", cell[r, i])
				if (i < nf)
					line = line "  "
			}
			sub(/ +$/, "", line)
			print line
			if (r == 1)
				print rule
		}
		print rule
	}'
}

# One line per sample row of every report, tagged with the run's
# column label: label class symbol self%.  Classes: idle (the swapper
# task), pg (postgres in its own binary or libraries), kernel (any
# command, kernel symbols), mee, bh, driver, other.
extract()
{
	for D in "$@"; do
		# A bare run name is looked up under the results directory.
		[ -d "${D}" ] || D="${RESULTS}/${D}"
		U="$(basename "${D}" | sed 's/^c[0-9]*-u0*//')"
		C="$(basename "${D}" | sed 's/^c\([0-9]*\)-u.*/\1/')"
		R="${D}/${U}/db/$(hostname)/profile/perf-report.txt"
		[ -f "${R}" ] || continue
		grep -E '^ +[0-9.]+% +[0-9.]+% +[0-9]+ ' "${R}" |
		awk -v label="${C}/${U}" '
		{
			self = $2; sub(/%/, "", self)
			cmd = $4; dso = $5; sym = $NF
			if (cmd == "swapper")
				class = "idle"
			else if (dso == "[kernel.kallsyms]")
				class = "kernel"
			else if (cmd == "postgres")
				class = "pg"
			else if (cmd ~ /^MarketExchange/)
				class = "mee"
			else if (cmd ~ /^BrokerageHouse/)
				class = "bh"
			else if (cmd ~ /^DriverMain/)
				class = "driver"
			else
				class = "other"
			print label, class, sym, self
		}'
	done
}

DATA="$(extract "$@")"
LABELS="$(echo "${DATA}" | awk '!seen[$1]++ {print $1}' | tr '\n' ' ')"

echo "Share of samples by component, percent:"
echo
{
	echo "Component ${LABELS}"
	for CLASS in idle kernel pg mee bh driver other; do
		printf '%s' "${CLASS}"
		for L in ${LABELS}; do
			printf ' %s' "$(echo "${DATA}" | awk -v l="${L}" -v c="${CLASS}" \
					'$1 == l && $2 == c { s += $4 } END { printf "%.1f", s }')"
		done
		echo
	done
} | rst_table

for CLASS in pg kernel; do
	echo
	if [ "${CLASS}" = "pg" ]; then
		echo "PostgreSQL backend symbols, percent of all samples:"
	else
		echo "Kernel symbols, from any process, percent of all samples:"
	fi
	echo
	{
		echo "Symbol ${LABELS}"
		# Rank symbols by their largest share in any run, then print
		# each with its share in every run.
		echo "${DATA}" | awk -v c="${CLASS}" -v labels="${LABELS}" \
				-v top="${TOP}" '
		BEGIN { n = split(labels, lab, " ") }
		$2 == c {
			v[$3, $1] += $4
			if (v[$3, $1] > best[$3])
				best[$3] = v[$3, $1]
		}
		END {
			for (s in best)
				order[++m] = s
			# Selection sort by best share, descending.
			for (i = 1; i <= m && i <= top; i++) {
				k = i
				for (j = i + 1; j <= m; j++)
					if (best[order[j]] > best[order[k]])
						k = j
				t = order[i]; order[i] = order[k]; order[k] = t
				line = order[i]
				for (l = 1; l <= n; l++)
					line = line sprintf(" %.1f", v[order[i], lab[l]])
				print line
			}
		}'
	} | rst_table
done
exit 0
