#!/bin/sh
#
# Run one complete scale-factor phase: rebuild the database at a given
# customer count, smoke test it, then measure a list of user counts.
#
# Usage: phase.sh CUSTOMERS USERS [USERS ...]
#
# Example, a full first-pass phase:
#     phase.sh 50000 8 16 24 32
#
# Example, a cheap follow-up phase once the best user count is known:
#     phase.sh 30000 12 16 20
#
# Each user count is a separate single-point test, so a phase can be
# interrupted between points and resumed by rerunning sweep.sh for the
# ones that are missing.

set -e

. "$(dirname "$0")/env.sh"

if [ "${#}" -lt 2 ]; then
	echo "usage: $(basename "${0}") CUSTOMERS USERS [USERS ...]"
	exit 1
fi

CUSTOMERS="${1}"
shift

HERE="$(dirname "$0")"

# Rebuild unless the database already holds exactly this many
# customers and was built to the end.  The customer table is loaded
# early, so a build that died after it would pass a check on the
# count alone; the C stored functions are loaded last, so their
# presence means the build finished.
LOADED="$(psql -X -A -t -d "${DBNAME}" -c \
		"SELECT count(*) FROM customer;" 2> /dev/null || echo none)"
CFUNCS="$(psql -X -A -t -d "${DBNAME}" -c \
		"SELECT count(*) FROM pg_proc p JOIN pg_language l
		     ON p.prolang = l.oid
		  WHERE p.pronamespace = 'public'::regnamespace
		    AND l.lanname = 'c';" 2> /dev/null || echo 0)"
if [ "${LOADED}" = "${CUSTOMERS}" ] && [ "${CFUNCS}" -eq 24 ]; then
	echo "database already holds ${CUSTOMERS} customers, skipping rebuild"
else
	echo "database holds ${LOADED} customers and ${CFUNCS} C functions," \
			"rebuilding for ${CUSTOMERS}"
	"${HERE}/build-db.sh" "${CUSTOMERS}"
fi

SMOKEDIR="${SMOKERESULTS}/c${CUSTOMERS}-smoke"
if [ "${DURATION}" -ne 3600 ]; then
	SMOKEDIR="${SMOKEDIR}-d${DURATION}"
fi
if [ -d "${SMOKEDIR}" ]; then
	echo "c${CUSTOMERS} already smoke tested, skipping"
else
	"${HERE}/smoke.sh" "${CUSTOMERS}"
fi

for U in "$@"; do
	if [ -d "$(test_dirname "${CUSTOMERS}" "${U}")" ]; then
		echo "c${CUSTOMERS} u${U} already done, skipping"
		continue
	fi
	"${HERE}/sweep.sh" "${CUSTOMERS}" "${U}"
done

echo
echo "=== phase c${CUSTOMERS} complete ==="
"${HERE}/collect.sh"
