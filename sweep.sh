#!/bin/sh
#
# Run one dbt5 test-user-scaling sweep against the currently loaded
# database.
#
# Usage: sweep.sh CUSTOMERS START [STEP STOP]
#
# With one user count, a single test is run.  Results go to
# ${RESULTS}/c<CUSTOMERS>-u<START>[-<STOP>-by<STEP>].
#
# The database must already be built at CUSTOMERS customers and be
# running.  Nothing here starts, stops, or reloads it.

set -e

. "$(dirname "$0")/env.sh"

if [ "${#}" -ne 1 ] && [ "${#}" -ne 2 ] && [ "${#}" -ne 4 ]; then
	echo "usage: $(basename "${0}") CUSTOMERS START [STEP STOP]"
	exit 1
fi

CUSTOMERS="${1}"
START="${2}"
STEP="${3:-1}"
STOP="${4:-${2}}"

if [ "${STOP}" -gt 64 ]; then
	echo "refusing to test more than 64 users"
	exit 1
fi

OUTDIR="$(test_dirname "${CUSTOMERS}" "${START}" "${STOP}" "${STEP}")"

# Sanity check the customer count actually in the database, since a
# mismatched -t silently invalidates the run.
LOADED="$(psql -X -A -t -d "${DBNAME}" -c "SELECT count(*) FROM customer;")"
if [ "${LOADED}" -ne "${CUSTOMERS}" ]; then
	echo "database holds ${LOADED} customers, expected ${CUSTOMERS}"
	exit 1
fi

echo "Sweeping users ${START}..${STOP} step ${STEP} at ${CUSTOMERS}"
echo "customers, ${DURATION} s per test, into ${OUTDIR}"

# Measure on a quiet machine, and leave one behind.
stop_collectors

dbt5 test-user-scaling \
		-d "${DURATION}" \
		--warmup "${WARMUP}" \
		-n "${DBNAME}" \
		-t "${CUSTOMERS}" \
		${PROFILE_ARG} \
		--start "${START}" \
		--step "${STEP}" \
		--stop "${STOP}" \
		pgsql "${OUTDIR}"

stop_collectors

# TPC-E scaling: the configured customer count must support the
# reported throughput, i.e. trtps <= customers / 500, allowed here to
# run up to CEILING_MARGIN times that.
echo
awk -v c="${CUSTOMERS}" -v sf="${SCALE_FACTOR}" -v m="${CEILING_MARGIN}" \
		'NR == 1 {
	printf "ceiling at %s customers: %.2f trtps (%s x %s/%s)\n",
			c, c / sf * m, m, c, sf
	next
}
{
	flag = ($2 > c / sf * m) ? "  OVER CEILING" : ""
	printf "%4s users  %8s trtps%s\n", $1, $2, flag
}' "${OUTDIR}/results.dat"
