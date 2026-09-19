#!/bin/sh
#
# Regenerate perf.folded and flamegraph.svg for one or more test runs
# with the host's perl.
#
# Usage: flamegraph.sh RUNDIR [RUNDIR ...]
#        flamegraph.sh --all
#
# RUNDIR is a directory holding db/<host>/profile/perf.txt, for
# example c5000-u16/16.  With --all, every such directory under
# ${RESULTS} whose perf.folded is missing or empty.
#
# The AppImage's own post-processing leaves both files empty: it
# exports PERL5LIB at its bundled perl 5.28 modules while the scripts
# run under the host perl through their shebang, which cannot compile
# them.  The scripts themselves are fine, so run them from the dbt5
# build tree with a clean environment.

. "$(dirname "$0")/env.sh"

SCRIPTS="${SCRIPTS:-${HOME}/dbt5/build/AppDir/usr/bin}"

fold()
{
	P="${1}/db/$(hostname)/profile"
	if [ ! -s "${P}/perf.txt" ]; then
		echo "${1}: no perf.txt"
		return
	fi
	env -u PERL5LIB /usr/bin/perl "${SCRIPTS}/stackcollapse-perf.pl" \
			"${P}/perf.txt" > "${P}/perf.folded"
	SUBTITLE=""
	[ -f "${P}/start.txt" ] && read -r SUBTITLE < "${P}/start.txt"
	env -u PERL5LIB /usr/bin/perl "${SCRIPTS}/flamegraph.pl" \
			--title "$(hostname)" --subtitle "${SUBTITLE}" \
			"${P}/perf.folded" > "${P}/flamegraph.svg"
	printf '%s: %s stacks, %s bytes of svg\n' "${1}" \
			"$(grep -c . "${P}/perf.folded")" \
			"$(wc -c < "${P}/flamegraph.svg")"
}

if [ "${1}" = "--all" ]; then
	find "${RESULTS}" -mindepth 6 -maxdepth 6 -name perf.txt \
			-path '*/db/*/profile/*' 2> /dev/null | sort -V |
	while IFS= read -r F; do
		D="$(echo "${F}" | sed 's|/db/[^/]*/profile/perf.txt$||')"
		case "${D}" in
		(*.invalid*) continue ;;
		esac
		if [ ! -s "${D}/db/$(hostname)/profile/perf.folded" ]; then
			fold "${D}"
		fi
	done
else
	for D in "$@"; do
		fold "${D}"
	done
fi
