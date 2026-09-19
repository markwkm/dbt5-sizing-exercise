#!/bin/sh
#
# Emit what the per run PostgreSQL statistics say about caching and
# index use, as reStructuredText tables for RESULTS.rst.
#
# Usage: dbstat-table.sh [RUN ...]
#
# RUN is a run directory such as c32000-u18.  The default is one run
# per customer count, the reported optimum of each.  The data is the
# statistics collector's per minute samples of pg_stat_all_tables
# joined with pg_statio_all_tables (dbstat/pg_stat_tables.csv) and of
# pg_stat_all_indexes joined with pg_statio_all_indexes
# (dbstat/pg_stat_indexes.csv).  Every figure is the difference
# between the first and the last sample of a run, which spans the
# measurement interval and the one minute warmup before it.  Rates
# are per second of that span.
#
# Relation sizes come from relation-sizes-32000.txt, captured with
# pg_relation_size on the 32000 customer database, when it exists.
#
# The last table needs the index scans of every run.  They are kept
# in dbstat-index-use.txt, one line per run and index, and a run is
# read only once, so that a routine update touches only new runs.

. "$(dirname "$0")/env.sh"

HERE="$(dirname "$0")"
RUNS="${*:-c5000-u16 c30000-u24 c32000-u18 c35000-u28 c97000-u16}"
SIZES="${HERE}/relation-sizes-32000.txt"
USECACHE="${HERE}/dbstat-index-use.txt"
TAB="$(printf '\t')"

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

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

# Sort the body of a table on a leading numeric key, descending, and
# drop the key.  The key is separated from the row by a tab.
by_key()
{
	sort -t "${TAB}" -k1,1nr -k2 | cut -f 2-
}

# The dbstat directory of a run, and the run's label, "5000/16".
dbstat_dir()
{
	_u="$(ls "${RESULTS}/${1}" | head -n 1)"
	echo "${RESULTS}/${1}/${_u}/db/madrona/dbstat"
}

label()
{
	echo "${1}" | sed 's/^c//; s/-u0*/\//'
}

# Per table deltas of a run: schema table heap_read heap_hit idx_read
# idx_hit seq_scan seq_tup idx_scan n_upd n_hot seconds.
table_deltas()
{
	awk -F, '
	NR > 1 && ($3 == "public" || $3 == "pg_catalog") {
		k = $3 " " $4
		if (!(k in seen)) {
			seen[k] = 1
			if (t0 == "" || $1 < t0)
				t0 = $1
			hr0[k] = $5; hh0[k] = $6; ir0[k] = $7; ih0[k] = $8
			ss0[k] = $16; st0[k] = $18; is0[k] = $19
			nu0[k] = $23; nh0[k] = $25
		}
		if ($1 > t1)
			t1 = $1
		hr[k] = $5; hh[k] = $6; ir[k] = $7; ih[k] = $8
		ss[k] = $16; st[k] = $18; is[k] = $19
		nu[k] = $23; nh[k] = $25
	}
	END {
		for (k in hr)
			printf "%s %d %d %d %d %d %d %d %d %d %d\n", k,
				hr[k] - hr0[k], hh[k] - hh0[k], ir[k] - ir0[k],
				ih[k] - ih0[k], ss[k] - ss0[k], st[k] - st0[k],
				is[k] - is0[k], nu[k] - nu0[k], nh[k] - nh0[k],
				t1 - t0
	}' "${1}/pg_stat_tables.csv"
}

# Per index deltas of a run: index table scans blk_read blk_hit
# seconds.
index_deltas()
{
	awk -F, '
	NR > 1 && $4 == "public" {
		k = $6 " " $5
		if (!(k in seen)) {
			seen[k] = 1
			if (t0 == "" || $1 < t0)
				t0 = $1
			s0[k] = $7; r0[k] = $16; h0[k] = $17
		}
		if ($1 > t1)
			t1 = $1
		s[k] = $7; r[k] = $16; h[k] = $17
	}
	END {
		for (k in s)
			printf "%s %d %d %d %d\n", k, s[k] - s0[k], r[k] - r0[k],
				h[k] - h0[k], t1 - t0
	}' "${1}/pg_stat_indexes.csv"
}

# Index scans of a run from the first and last samples only, for the
# cache of every run; the first and last 400 KB hold several samples.
index_scans_brief()
{
	{
		head -c 400000 "${1}/pg_stat_indexes.csv"
		echo
		tail -c 400000 "${1}/pg_stat_indexes.csv"
	} | awk -F, -v run="${2}" '
	NF >= 17 && $4 == "public" && $7 ~ /^[0-9]+$/ {
		k = $6
		if (!(k in seen)) {
			seen[k] = 1
			s0[k] = $7
		}
		s[k] = $7
	}
	END {
		for (k in s)
			printf "%s %s %d\n", run, k, s[k] - s0[k]
	}'
}

N=0
LABELS=""
for RUN in ${RUNS}; do
	D="$(dbstat_dir "${RUN}")"
	[ -f "${D}/pg_stat_tables.csv" ] || continue
	N=$((N + 1))
	L="$(label "${RUN}")"
	LABELS="${LABELS} ${L}"
	table_deltas "${D}" > "${TMP}/t${N}"
	index_deltas "${D}" > "${TMP}/i${N}"
done
# The run the tables are ordered by: the third, the answer, or the
# last when there are fewer.
O=$((N >= 3 ? 3 : N))

# Every run's index scans, cached.
touch "${USECACHE}"
for D in "${RESULTS}"/c[0-9]*-u[0-9][0-9]; do
	RUN="$(basename "${D}")"
	grep -q "^${RUN} " "${USECACHE}" && continue
	DS="$(dbstat_dir "${RUN}")"
	[ -f "${DS}/pg_stat_indexes.csv" ] || continue
	index_scans_brief "${DS}" "${RUN}" >> "${USECACHE}"
done

if [ -f "${SIZES}" ]; then
	cp "${SIZES}" "${TMP}/sizes"
else
	: > "${TMP}/sizes"
fi

header()
{
	_line="${1}"
	for _l in ${LABELS}; do
		_line="${_line}  ${_l}"
	done
	echo "${_line}${2}"
}

cat <<EOT
Buffer cache hit ratio of heap blocks in shared_buffers, percent, by
table, over each run.  GB is the table's heap size at 32000
customers.  Tables are ordered by their block requests in the third
run.

EOT
{
	header "Table  GB"
	awk -v n="${N}" -v o="${O}" '
	FILENAME == ARGV[1] { if ($2 == "r") size[$1] = $3; next }
	$1 == "public" {
		f = substr(FILENAME, length(FILENAME))
		k = $2
		tables[k] = 1
		hr[k, f] = $3; hh[k, f] = $4
		req[k, f] = $3 + $4 + $5 + $6
	}
	END {
		for (k in tables) {
			line = k "  " ((k in size) ? sprintf("%.2f", size[k]) : "-")
			for (i = 1; i <= n; i++) {
				t = hr[k, i] + hh[k, i]
				line = line "  " ((t > 0) ? sprintf("%.1f", 100 * hh[k, i] / t) : "-")
			}
			printf "%d\t%s\n", req[k, o], line
		}
	}' "${TMP}/sizes" "${TMP}"/t[1-9] | by_key
} | rst_table
echo

cat <<EOT
Buffer cache hit ratio of index blocks in shared_buffers, percent, by
table, the same runs and order.

EOT
{
	header "Table"
	awk -v n="${N}" -v o="${O}" '
	$1 == "public" {
		f = substr(FILENAME, length(FILENAME))
		k = $2
		tables[k] = 1
		ir[k, f] = $5; ih[k, f] = $6
		req[k, f] = $3 + $4 + $5 + $6
	}
	END {
		for (k in tables) {
			line = k
			for (i = 1; i <= n; i++) {
				t = ir[k, i] + ih[k, i]
				line = line "  " ((t > 0) ? sprintf("%.1f", 100 * ih[k, i] / t) : "-")
			}
			printf "%d\t%s\n", req[k, o], line
		}
	}' "${TMP}"/t[1-9] | by_key
} | rst_table
echo

cat <<EOT
Share of all block requests and of the blocks read from the
operating system, percent, by table, in the third and the last run;
the twelve tables with the largest share of the reads in the third
run, and the system catalogs together.

EOT
{
	LA="$(echo ${LABELS} | cut -d' ' -f${O})"
	LB="$(echo ${LABELS} | cut -d' ' -f${N})"
	echo "Table  Req_${LA}  Read_${LA}  Req_${LB}  Read_${LB}"
	awk -v n="${N}" -v o="${O}" '
	$1 == "public" || $1 == "pg_catalog" {
		f = substr(FILENAME, length(FILENAME))
		k = ($1 == "public") ? $2 : "(catalogs)"
		tables[k] = 1
		req[k, f] += $3 + $4 + $5 + $6
		rd[k, f] += $3 + $5
		treq[f] += $3 + $4 + $5 + $6
		trd[f] += $3 + $5
	}
	END {
		for (k in tables)
			printf "%d\t%s  %.2f  %.2f  %.2f  %.2f\n",
				(k == "(catalogs)") ? -1 : rd[k, o], k,
				100 * req[k, o] / treq[o], 100 * rd[k, o] / trd[o],
				100 * req[k, n] / treq[n], 100 * rd[k, n] / trd[n]
	}' "${TMP}"/t[1-9] | by_key | awk 'NR <= 12 || /^\(catalogs\)/'
} | rst_table
echo

cat <<EOT
Sequential scans per second by table, with the rows each scan read
in the third run; tables scanned sequentially in any of the runs.

EOT
{
	header "Table  Rows/scan"
	awk -v n="${N}" -v o="${O}" '
	$1 == "public" {
		f = substr(FILENAME, length(FILENAME))
		k = $2
		if ($7 > 0)
			tables[k] = 1
		ss[k, f] = $7; st[k, f] = $8; sec[f] = $12
	}
	END {
		for (k in tables) {
			rows = "-"
			for (i = n; i >= 1; i--)
				if (ss[k, i] > 0)
					rows = sprintf("%.0f", st[k, i] / ss[k, i])
			if (ss[k, o] > 0)
				rows = sprintf("%.0f", st[k, o] / ss[k, o])
			line = k "  " rows
			for (i = 1; i <= n; i++)
				line = line "  " sprintf("%.2f", ss[k, i] / sec[i])
			printf "%d\t%s\n", ss[k, o], line
		}
	}' "${TMP}"/t[1-9] | by_key
} | rst_table
echo

cat <<EOT
Updates per second and the share of them done as heap only tuple
(HOT) updates, percent, by table, in the first and the third run;
tables with more than one update per second in the third run.

EOT
{
	LA="$(echo ${LABELS} | cut -d' ' -f1)"
	LB="$(echo ${LABELS} | cut -d' ' -f${O})"
	echo "Table  Upd/s_${LA}  HOT_${LA}  Upd/s_${LB}  HOT_${LB}"
	awk -v n="${N}" -v o="${O}" '
	$1 == "public" {
		f = substr(FILENAME, length(FILENAME))
		k = $2
		nu[k, f] = $10; nh[k, f] = $11; sec[f] = $12
		if (f == o && $10 / $12 > 1)
			tables[k] = 1
	}
	END {
		for (k in tables)
			printf "%d\t%s  %.1f  %s  %.1f  %s\n", nu[k, o], k,
				nu[k, 1] / sec[1],
				(nu[k, 1] > 0) ? sprintf("%.1f", 100 * nh[k, 1] / nu[k, 1]) : "-",
				nu[k, o] / sec[o],
				(nu[k, o] > 0) ? sprintf("%.1f", 100 * nh[k, o] / nu[k, o]) : "-"
	}' "${TMP}"/t[1-9] | by_key
} | rst_table
echo

cat <<EOT
System catalog tables, all of pg_catalog together: block requests
per second, their share of all block requests, percent, and their
hit ratio in shared_buffers, percent.

EOT
{
	echo "Run  Requests/s  Share  Hit"
	awk -v n="${N}" -v labels="${LABELS}" '
	BEGIN { split(labels, lab, " ") }
	{
		f = substr(FILENAME, length(FILENAME))
		r = $3 + $4 + $5 + $6
		all[f] += r
		sec[f] = $12
		if ($1 == "pg_catalog") {
			cat[f] += r
			hit[f] += $4 + $6
		}
	}
	END {
		for (i = 1; i <= n; i++)
			printf "%s  %.0f  %.3f  %.1f\n", lab[i], cat[i] / sec[i],
				100 * cat[i] / all[i],
				(cat[i] > 0) ? 100 * hit[i] / cat[i] : 0
	}' "${TMP}"/t[1-9]
} | rst_table
echo

M="$(cut -d' ' -f1 "${USECACHE}" | sort -u | wc -l)"
cat <<EOT
Index scans per second by index, and the number of the ${M} reportable
runs in which the index was scanned at all (Used).  Indexes are
ordered by their scans in the third run.

EOT
{
	header "Index" "  Used"
	awk -v n="${N}" -v o="${O}" '
	FILENAME == ARGV[1] { if ($3 > 0) used[$2]++; next }
	{
		f = substr(FILENAME, length(FILENAME))
		k = $1
		idx[k] = 1
		sc[k, f] = $3; sec[f] = $6
	}
	END {
		for (k in idx) {
			line = k
			for (i = 1; i <= n; i++)
				line = line "  " sprintf("%.1f", sc[k, i] / sec[i])
			printf "%d\t%s  %d\n", sc[k, o], line, used[k] + 0
		}
	}' "${USECACHE}" "${TMP}"/i[1-9] | by_key
} | rst_table
