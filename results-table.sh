#!/bin/sh
#
# Emit the phase 0 results as reStructuredText simple tables, so the
# tables in RESULTS.rst are generated from the runs rather than
# transcribed by hand.
#
# Usage: results-table.sh
#
# The first table is one row per reportable run: throughput, the gain
# over the previous user count, and the validity figures a run is
# checked on.  The second is stability.sh's assessment of each run.

. "$(dirname "$0")/env.sh"

# Print an RST simple table from whitespace separated rows on stdin,
# the first row being the header.  Numeric columns are right aligned.
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

# The search as it stands: collect.sh's verdict summary and the
# users-by-customers matrix, as a literal block.
echo "::"
echo
"$(dirname "$0")/collect.sh" | sed 's/^/    /'
echo

# Mean connections busy between the Market Exchange and the Brokerage
# House, from mee-load.sh, keyed by user count.
BUSY="$("$(dirname "$0")/mee-load.sh" | awk 'NR > 1 { print $1, $5 }')"

{
echo "Users trtps Gain TR_mix TR_rb TO_rb TR_max MEE_busy"
for D in "${RESULTS}"/c5000-u[0-9][0-9]; do
	[ -d "${D}" ] || continue
	U="$(basename "${D}" | sed 's/^c5000-u0*//')"
	S="${D}/${U}/summary.rst"
	[ -f "${S}" ] || continue
	awk -v u="${U}" '
	/Reported Throughput/ { trtps = $3 }
	$1 == "Trade" && $2 == "Result" && $3 !~ /\./ {
		trmix = $4; trrb = $5
	}
	$1 == "Trade" && $2 == "Order" && $3 !~ /\./ {
		torb = sprintf("%.2f", 100 * $5 / $3)
	}
	$1 == "Trade" && $2 == "Result" && $3 ~ /\./ { trmax = $6 }
	END { print u, trtps, trmix, trrb, torb, trmax }' "${S}"
done | sort -n | awk -v busy="${BUSY}" '
	BEGIN {
		n = split(busy, lines, "\n")
		for (i = 1; i <= n; i++) {
			split(lines[i], f, " ")
			b[f[1]] = f[2]
		}
	}
	{
		gain = (NR > 1) ? sprintf("%.2f", $2 - prev) : "-"
		prev = $2
		print $1, $2, gain, $3, $4, $5, $6, ($1 in b) ? b[$1] : "-"
	}'
} | rst_table

echo
{
echo "Run Reported Steady CV Noise Drift/h Ramp Verdict"
"$(dirname "$0")/stability.sh" --all 2> /dev/null |
		awk 'NR > 1 && $1 ~ /^c[0-9]+-u[0-9]+\// && $1 !~ /invalid/ &&
				NF == 8 { print }' | sort -t- -k1.2,1n -k2.2,2n
} | rst_table
