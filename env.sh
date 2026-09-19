#!/bin/sh
# Shared environment for the profiled rerun of the DBT-5 scale factor
# search.  Source this, do not execute it.
#
# Every setting below can be overridden from the environment, so the
# same scripts serve both short shakedowns and the real runs:
#
#     DURATION=1200 ./phase.sh 5000 1 2 3 4
#
# Differences from ../scaling/env.sh:
#
# * results live next to these scripts rather than in ~/claude-tests
# * every test passes --profile, so dbt5 run captures a perf profile
#   at the middle of the measurement interval
# * "dbt5" is no longer in the collector kill pattern.  The wrapper
#   leak it was there for is fixed, and a live "dbt5 test-user-scaling"
#   command line names this results tree, so matching it would kill
#   the test in progress along with its AppImage mount

# Use the locally built PostgreSQL 18, not the packaged 17.  dbt5
# pgsql-load-stored-procs resolves the C function .sql files through
# "pg_config --sharedir", so PATH order decides which install is used.
PGBIN="${PGBIN:-${HOME}/.local/pgsql-18/bin}"
PATH="${PGBIN}:${HOME}/.local/bin:${PATH}"
export PATH

# The dbt5 AppImage this campaign runs, ahead of the one in
# ~/.local/bin.  It is built from the dbt5 branch
# mee-deliver-concurrently, which lets the Market Exchange deliver
# Trade Results over several connections; see README.rst.
HERE="$(cd "$(dirname "${0}")" && pwd)"
PATH="${HERE}/bin:${PATH}"

# Nothing sourcing this file needs the AppImage's bundled libraries,
# and a locally built psql dies against its old libpq.
unset LD_LIBRARY_PATH

PGDATA="${PGDATA:-/perffarm/pgdata}"
PGLOG="${PGLOG:-/perffarm/pglog/postgres.log}"
export PGDATA PGLOG

DBNAME="${DBNAME:-dbt5}"
DURATION="${DURATION:-3600}"
SMOKE_DURATION="${SMOKE_DURATION:-600}"
WARMUP="${WARMUP:-60}"
SCALE_FACTOR="${SCALE_FACTOR:-500}"
# TPC-E scaling: trtps must not exceed customers / SCALE_FACTOR.  The
# specification tolerates 2 percent over that, reported as the nominal
# rate (clause 6.7.1.2), so that is the margin the verdicts use.
CEILING_MARGIN="${CEILING_MARGIN:-1.02}"
ITD="${ITD:-300}"
PARALLELISM="${PARALLELISM:-20}"
RESULTS="${RESULTS:-${HERE}/runs}"
# Build logs and the loader output go here, and smoke tests here.
BUILDLOGS="${BUILDLOGS:-${HERE}/build}"
SMOKERESULTS="${SMOKERESULTS:-${HERE}/smoke}"

# Profile every test.  dbt5 run samples with perf for 20 seconds at
# the middle of the measurement interval.  Set PROFILE=0 to run
# without it.
PROFILE="${PROFILE:-1}"
PROFILE_ARG=""
if [ "${PROFILE}" -eq 1 ]; then
	PROFILE_ARG="--profile"
fi

export DBNAME DURATION SMOKE_DURATION WARMUP SCALE_FACTOR ITD
export PARALLELISM RESULTS BUILDLOGS SMOKERESULTS CEILING_MARGIN
export PROFILE PROFILE_ARG

# Collectors from a finished test.  Only processes whose command line
# names this campaign's results tree are considered, and the program
# name has to be the executable rather than merely a word appearing in
# the arguments, so an unrelated process is never signaled.
COLLECTORS='^(sar|sadc|sadf|spar|pidstat|iostat|ts-pgsql-stat)$'

stop_collectors()
{
	_snap="$(ps -eo pid,args 2> /dev/null)"
	_pids="$(echo "${_snap}" | awk -v res="${RESULTS}" \
			-v pat="${COLLECTORS}" -v me="$$" '
		$1 == me { next }
		index($0, res) == 0 { next }
		{
			prog = $2; sub(/.*\//, "", prog)
			next2 = $3; sub(/.*\//, "", next2)
			if (prog ~ pat || next2 ~ pat)
				print $1
		}')"

	[ -z "${_pids}" ] && return 0

	# Report the full command line, not just the pid.  A kill that
	# turns out to have been wrong is otherwise impossible to
	# reconstruct after the fact.
	echo "stopping leftover collectors:"
	echo "${_snap}" | awk -v list="$(echo "${_pids}" | tr '\n' ' ')" '
		BEGIN { n = split(list, a, " "); for (i = 1; i <= n; i++) want[a[i]] = 1 }
		want[$1] { print "    " $0 }'
	# Both kills are allowed to fail.  Anything TERM already reaped is
	# gone by the time KILL runs, and kill reports non-zero for a pid
	# that no longer exists, which under set -e would abort the caller
	# in the middle of a phase.
	# shellcheck disable=SC2086
	kill -TERM ${_pids} 2> /dev/null || true
	sleep 2
	# shellcheck disable=SC2086
	kill -KILL ${_pids} 2> /dev/null || true
	return 0
}

# Directory name for one test.  Results of the reference duration get
# clean names.  Anything else is tagged so a 1200 second run can never
# be mistaken for, or collide with, a 3600 second measurement.
test_dirname()
{
	_customers="${1}"
	_start="${2}"
	_stop="${3:-${2}}"
	_step="${4:-1}"

	if [ "${_start}" = "${_stop}" ]; then
		_name="$(printf 'c%s-u%02d' "${_customers}" "${_start}")"
	else
		_name="$(printf 'c%s-u%02d-%02d-by%d' "${_customers}" \
				"${_start}" "${_stop}" "${_step}")"
	fi

	if [ "${DURATION}" -ne 3600 ]; then
		_name="${_name}-d${DURATION}"
	fi

	echo "${RESULTS}/${_name}"
}
