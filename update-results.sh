#!/bin/sh
#
# Regenerate the tables in RESULTS.rst.  Everything between the
# ".. tables-begin" and ".. tables-end" comment lines is replaced by
# the output of results-table.sh, everything between
# ".. io-tables-begin" and ".. io-tables-end" by the output of
# io-table.sh, everything between ".. util-tables-begin" and
# ".. util-tables-end" by the output of utilization-table.sh,
# everything between ".. profile-tables-begin" and
# ".. profile-tables-end" by two groups of profile-table.sh output,
# everything between ".. dbstat-tables-begin" and
# ".. dbstat-tables-end" by the output of dbstat-table.sh, and the
# "Updated" line by the time.

set -e

cd "$(dirname "$0")"

TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

{
	sed -n '1,/^\.\. tables-begin/p' RESULTS.rst
	echo
	./results-table.sh
	echo
	sed -n '/^\.\. tables-end/,/^\.\. io-tables-begin/p' RESULTS.rst
	./io-table.sh
	echo
	sed -n '/^\.\. io-tables-end/,/^\.\. util-tables-begin/p' RESULTS.rst
	./utilization-table.sh
	echo
	sed -n '/^\.\. util-tables-end/,/^\.\. profile-tables-begin/p' RESULTS.rst
	echo
	echo "**Across the regimes at 5000 customers**, 1, 4, 8, 16, 24 and 32"
	echo "users: the end of the first linear regime, the second, the"
	echo "plateau, and the decline."
	echo
	./profile-table.sh c5000-u01 c5000-u04 c5000-u08 c5000-u16 \
			c5000-u24 c5000-u32
	echo
	echo "**Across the scales**, at the reported optimum of each, with"
	echo "40 users at 30000 for the upper end of its plateau."
	echo
	./profile-table.sh c5000-u16 c30000-u24 c30000-u40 \
			c97000-u16
	echo
	sed -n '/^\.\. profile-tables-end/,/^\.\. dbstat-tables-begin/p' RESULTS.rst
	echo
	./dbstat-table.sh
	echo
	sed -n '/^\.\. dbstat-tables-end/,$p' RESULTS.rst
} > "${TMP}"

N="$(ls -d runs/c[0-9]*-u[0-9][0-9] 2> /dev/null | while read -r D; do
	U="$(basename "${D}" | sed 's/^c[0-9]*-u0*//')"
	[ -f "${D}/${U}/summary.rst" ] && echo "${D}"
done | wc -l)"
STAMP="$(date -u '+%Y-%m-%d %H:%M UTC')"
sed -e "s/^\*\*Updated .*/**Updated ${STAMP}, ${N} reportable runs.**/" \
		"${TMP}" > RESULTS.rst
