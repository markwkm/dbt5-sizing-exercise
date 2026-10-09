#!/bin/sh
#
# Rebuild the DBT-5 database at a given customer count and load the
# PL/C stored functions.
#
# Usage: build-db.sh CUSTOMERS
#
# The database is dropped and rebuilt from scratch.  dbt5 pgsql-build-db
# always loads the PL/pgSQL stored functions, so they are dropped and
# replaced with the C versions afterwards.

set -e

. "$(dirname "$0")/env.sh"

if [ "${#}" -ne 1 ]; then
	echo "usage: $(basename "${0}") CUSTOMERS"
	exit 1
fi

CUSTOMERS="${1}"
mkdir -p "${BUILDLOGS}" "${RESULTS}"
LOG="${BUILDLOGS}/c${CUSTOMERS}-build.log"

# EGenLoader loads in units of 1000 customers, so the total must be a
# multiple of 1000.  Multiples of 5000 are used here to keep the set of
# tested scales small and memorable.
if [ $(( CUSTOMERS % 1000 )) -ne 0 ]; then
	echo "customer count must be a multiple of 1000, got ${CUSTOMERS}"
	exit 1
fi
if [ $(( CUSTOMERS % 5000 )) -ne 0 ]; then
	echo "warning: ${CUSTOMERS} is not a multiple of 5000"
fi

# The exercise may return to a customer count after the database has
# been replaced, so keep old build logs rather than refusing to rebuild.
if [ -e "${LOG}" ]; then
	N=1
	while [ -e "${LOG}.${N}" ]; do
		N=$(( N + 1 ))
	done
	mv "${LOG}" "${LOG}.${N}"
	echo "previous build log kept as ${LOG}.${N}"
fi

echo "Building ${CUSTOMERS}-customer database, logging to ${LOG}"

# A pipeline exits with the status of its last command, so piping the
# build into tee would report tee's success and hide a failed build
# from the caller's set -e.  "set -o pipefail" is not POSIX, so the
# real status is carried out through a file instead.
STATUS="$(mktemp)"
trap 'rm -f "${STATUS}"' EXIT

{
	echo "=== started $(date -Is) ==="

	if pg_isready > /dev/null 2>&1; then
		echo "database server already running"
	else
		pg_ctl -D "${PGDATA}" -l "${PGLOG}" start
		until pg_isready > /dev/null 2>&1; do
			sleep 2
		done
	fi

	# Drop the old database directly rather than with the build-db -r
	# flag.  That flag only takes effect together with -U, and -U also
	# makes build-db stop and restart the cluster through
	# dbt5-pgsql-start-db, which removes postmaster.pid and re-applies
	# server parameters.  Nothing here is allowed to disturb the
	# running cluster or its settings, so the drop is done by hand.
	# These hold connections to the database about to be dropped.
	stop_collectors

	echo "=== dropping ${DBNAME} $(date -Is) ==="
	psql -X -d postgres -c \
			"SELECT pg_terminate_backend(pid)
			   FROM pg_stat_activity
			  WHERE datname = '${DBNAME}'
			    AND pid <> pg_backend_pid();" > /dev/null
	dropdb --if-exists "${DBNAME}"

	echo "=== build-db $(date -Is) ==="
	# -l CUSTOM must be given explicitly.  build-db --help claims
	# CUSTOM is the default, but the script sets MODE="FLAT", and the
	# FLAT path generates intermediate files into the read-only
	# AppImage mount and ignores --parallelism entirely.
	# The loader writes its own logs into the working directory.
	cd "${BUILDLOGS}"
	dbt5 pgsql-build-db \
			-l CUSTOM \
			-d "${DBNAME}" \
			-c "${CUSTOMERS}" \
			-t "${CUSTOMERS}" \
			-s "${SCALE_FACTOR}" \
			-w "${ITD}" \
			--parallelism "${PARALLELISM}"

	echo "=== swapping PL/pgSQL functions for PL/C $(date -Is) ==="
	dbt5 pgsql-drop-stored-procs -d "${DBNAME}"
	dbt5 pgsql-load-stored-procs -d "${DBNAME}" -t c

	echo "=== spreading broker over several pages $(date -Is) ==="
	# At 5000 customers the 50 broker rows fit in one page and the
	# planner reads them with a sequential scan, which under the
	# serializable isolation Trade Result runs at takes a predicate
	# lock on the whole relation.  Every Trade Result updates a broker
	# row, so with several in flight each conflicts with all the
	# others, and most fail and retry.  At larger scales the table
	# spans several pages and the planner uses the index, whose locks
	# cover only the row read.  A low fill factor gives the small
	# table the same shape.
	psql -X -v ON_ERROR_STOP=1 -d "${DBNAME}" \
			-c "ALTER TABLE broker SET (fillfactor = 10);" \
			-c "VACUUM FULL ANALYZE broker;"
	psql -X -d "${DBNAME}" -c \
			"SELECT relpages FROM pg_class WHERE relname = 'broker';"

	echo "=== verifying $(date -Is) ==="
	psql -X -d "${DBNAME}" -c \
			"SELECT l.lanname, count(*)
			   FROM pg_proc p
			   JOIN pg_language l ON p.prolang = l.oid
			  WHERE p.pronamespace = 'public'::regnamespace
			  GROUP BY 1;"
	psql -X -d "${DBNAME}" -c "SELECT count(*) AS customers FROM customer;"
	psql -X -d "${DBNAME}" -c \
			"SELECT pg_size_pretty(pg_database_size('${DBNAME}'))
					AS size;"

	echo 0 > "${STATUS}"
	echo "=== finished $(date -Is) ==="
} 2>&1 | tee "${LOG}"

# set -e aborts the block's subshell on the first failure, so the
# sentinel is simply absent when any step failed.
RC="$(cat "${STATUS}" 2> /dev/null)"
if [ -z "${RC}" ]; then
	RC=1
fi
if [ "${RC}" -ne 0 ]; then
	echo "build failed with status ${RC}, see ${LOG}"
	exit "${RC}"
fi
