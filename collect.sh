#!/bin/sh
#
# Report the exercise's results: the best run at each customer count
# against its ceiling, then every user count tested at every customer
# count.
#
# Usage: collect.sh [--all]
#
#   --all   also print one row per individual run

. "$(dirname "$0")/env.sh"

ALL=0
if [ "${1}" = "--all" ]; then
	ALL=1
fi

# customers, users, trtps, seconds, note -- one line per run.
emit_rows()
{
	find "${RESULTS}" "${SMOKERESULTS}" -mindepth 2 -maxdepth 2 \
			-name results.dat 2> /dev/null |
			sort -V |
	while IFS= read -r F; do
		DIR="$(basename "$(dirname "${F}")")"
		CUSTOMERS="$(echo "${DIR}" | sed -n 's/^c\([0-9]*\)-.*/\1/p')"
		[ -z "${CUSTOMERS}" ] && continue

		# Results quarantined by hand are not data.
		case "${DIR}" in
		(*.invalid*) continue ;;
		esac

		# A "-d<seconds>" suffix marks a non-reference duration.  A
		# smoke test ran for SMOKE_DURATION, which the directory name
		# does not record, so say so rather than guess a number.
		SECS="$(echo "${DIR}" | sed -n 's/.*-d\([0-9]*\)$/\1/p')"
		[ -z "${SECS}" ] && SECS=3600
		NOTE=""
		case "${DIR}" in
		(*-smoke*)
			SECS=smoke
			NOTE="smoke, not reportable"
			;;
		esac
		if [ ! "${SECS}" = "smoke" ] && [ "${SECS}" -ne 3600 ]; then
			NOTE="short run, not reportable"
		fi

		awk -v c="${CUSTOMERS}" -v secs="${SECS}" -v dir="${DIR}" \
				-v note="${NOTE}" \
				'NR > 1 && $2 != "" {
					print c, $1, $2, secs, dir "/" $1, note
				}' "${F}"
	done
}

# The exercise bisects on the ratio of throughput to ceiling, not on
# throughput, so lead with it.  The stability column says whether the
# run behind each number actually reached a steady rate.  A number from
# a run that never settled is not evidence of anything.
STAB="$("$(dirname "${0}")/stability.sh" --all 2> /dev/null)"

printf '%10s %10s %9s %6s %8s %7s %-7s  %s\n' \
		CUSTOMERS BEST_TRTPS CEILING USERS SECONDS RATIO VERDICT \
		STABILITY
# The best run at a customer count is the fastest reportable one.  A
# smoke test or a short run counts only where nothing reportable
# exists yet, or a warm-up could be reported as the answer.
{ echo "${STAB}"; echo "--"; emit_rows | sort -k1,1n; } |
		awk -v sf="${SCALE_FACTOR}" -v m="${CEILING_MARGIN}" '
	!split_seen { stab[$1] = $NF; if ($1 == "--") split_seen = 1; next }
	{
		if ($4 == "smoke")
			rank = 0
		else if ($4 + 0 != 3600)
			rank = 1
		else
			rank = 2
		c = $1
		if (!(c in best) || rank > brank[c] ||
				(rank == brank[c] && $3 + 0 > bval[c])) {
			best[c] = $0
			brank[c] = rank
			bval[c] = $3 + 0
		}
		if (!(c in seen)) {
			seen[c] = 1
			order[++n] = c
		}
	}
	END {
		for (i = 1; i <= n; i++) {
			c = order[i]
			split(best[c], f, " ")
			ceiling = c / sf * m
			ratio = f[3] / ceiling
			st = (f[5] in stab) ? stab[f[5]] : "-"
			printf "%10s %10s %9.1f %6s %8s %7.2f %-7s  %s\n", \
					c, f[3], ceiling, f[2], f[4], ratio,
					(ratio > 1) ? "over" : "under", st
		}
	}'

# Every user count tested at every customer count.  A trailing "s"
# marks a value from a smoke test and "*" a non-reference duration.
# Neither is reportable.  Both are shown because they are what the
# search actually used.
echo
emit_rows | sort -k1,1n -k2,2n | awk -v sf="${SCALE_FACTOR}" \
		-v m="${CEILING_MARGIN}" '
	{
		c = $1; u = $2; v = $3; secs = $4

		# One cell can be measured more than once, for instance a
		# smoke test and then a full run at the same user count.
		# Prefer the reportable one, and the faster of equals, rather
		# than whichever happened to be read last.
		if (secs == "smoke") {
			rank = 0
			v = v "s"
		} else if (secs + 0 != 3600) {
			rank = 1
			v = v "*"
		} else {
			rank = 2
		}
		k = c "," u
		if (!(k in cell) || rank > best[k] ||
				(rank == best[k] && $3 + 0 > val[k])) {
			cell[k] = v
			best[k] = rank
			val[k] = $3 + 0
		}
		custs[c] = 1
		users[u] = 1
	}
	END {
		nu = 0
		for (u in users)
			ulist[++nu] = u + 0
		for (i = 2; i <= nu; i++) {
			key = ulist[i]
			for (j = i - 1; j >= 1 && ulist[j] > key; j--)
				ulist[j + 1] = ulist[j]
			ulist[j + 1] = key
		}
		nc = 0
		for (c in custs)
			clist[++nc] = c + 0
		for (i = 2; i <= nc; i++) {
			key = clist[i]
			for (j = i - 1; j >= 1 && clist[j] > key; j--)
				clist[j + 1] = clist[j]
			clist[j + 1] = key
		}

		printf "%10s %9s", "CUSTOMERS", "CEILING"
		for (i = 1; i <= nu; i++)
			printf " %9s", "u" ulist[i]
		printf "\n"

		for (i = 1; i <= nc; i++) {
			c = clist[i]
			printf "%10d %9.1f", c, c / sf * m
			for (j = 1; j <= nu; j++) {
				k = c "," ulist[j]
				printf " %9s", (k in cell) ? cell[k] : "-"
			}
			printf "\n"
		}
	}'

[ "${ALL}" -eq 0 ] && exit 0

# One row per run, for when a single measurement needs checking.
echo
printf '%10s %6s %9s %9s %8s  %s\n' \
		CUSTOMERS USERS TRTPS CEILING SECONDS NOTE
emit_rows | awk -v sf="${SCALE_FACTOR}" -v m="${CEILING_MARGIN}" '{
	ceiling = $1 / sf * m
	note = ""
	for (i = 6; i <= NF; i++)
		note = note (note == "" ? "" : " ") $i
	if ($3 > ceiling)
		note = "OVER CEILING" (note == "" ? "" : "; " note)
	printf "%10s %6s %9s %9.1f %8s  %s\n", $1, $2, $3, ceiling, $4, note
}'
