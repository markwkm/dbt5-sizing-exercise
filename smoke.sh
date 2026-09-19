#!/bin/sh
#
# Short throwaway run to validate the pipeline and warm the buffer
# cache before committing hours to a sweep.
#
# Usage: smoke.sh CUSTOMERS
#
# Runs 16 users for SMOKE_DURATION seconds.  Discard the result.  It
# exists to catch missing PL/C functions or a wrong customer count
# in about ten minutes rather than an hour in, and to warm the
# buffer cache before the first measured point.

set -e

. "$(dirname "$0")/env.sh"

if [ "${#}" -ne 1 ]; then
	echo "usage: $(basename "${0}") CUSTOMERS"
	exit 1
fi

CUSTOMERS="${1}"

# Refuse to run against a database that is not the one asked for.
LOADED="$(psql -X -A -t -d "${DBNAME}" -c "SELECT count(*) FROM customer;")"
if [ "${LOADED}" -ne "${CUSTOMERS}" ]; then
	echo "database holds ${LOADED} customers, expected ${CUSTOMERS}"
	exit 1
fi

mkdir -p "${SMOKERESULTS}"
OUTDIR="${SMOKERESULTS}/c${CUSTOMERS}-smoke"
if [ "${DURATION}" -ne 3600 ]; then
	OUTDIR="${OUTDIR}-d${DURATION}"
fi

stop_collectors

dbt5 test-user-scaling \
		-d "${SMOKE_DURATION}" \
		--warmup "${WARMUP}" \
		-n "${DBNAME}" \
		-t "${CUSTOMERS}" \
		${PROFILE_ARG} \
		--start 16 \
		--stop 16 \
		pgsql "${OUTDIR}"

stop_collectors

echo
echo "smoke result:"
cat "${OUTDIR}/results.dat"
echo
echo "check for errors:"
grep -c ERROR "${OUTDIR}"/16/bh/*.log 2> /dev/null || echo "no bh error log"
