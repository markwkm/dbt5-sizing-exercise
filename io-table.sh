#!/bin/sh
#
# Emit the storage side of every reportable run as reStructuredText
# tables, one per customer count, for RESULTS.rst.
#
# Usage: io-table.sh
#
# Per run, over its measurement interval: reads and writes on the
# database volume in MB/s, I/O operations per second, the volume's
# utilization and mean request wait from sar, the processors' I/O
# wait, the PostgreSQL buffer cache hit rate from pg_stat_database,
# the rate at which blocks were requested from the operating system
# because they were not in shared_buffers, and the disk bytes read per
# Trade Result.

. "$(dirname "$0")/env.sh"

VOLUME="${VOLUME:-vg_data-lv_stripe}"

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

one_run()
{
	D="${1}"
	U="$(basename "${D}" | sed 's/^c[0-9]*-u0*//')"
	S="${D}/${U}/summary.rst"
	[ -f "${S}" ] || return
	START="$(awk -F, '$2 == "START" {print $1; exit}' \
			"${D}/${U}/driver/mix-dr.log")"
	SECS="$(awk '/Measurement Interval/ {print $NF * 60}' "${S}")"
	TRTPS="$(awk '/Reported Throughput/ {print $3}' "${S}")"
	TR="$(awk '$1 == "Trade" && $2 == "Result" && $3 !~ /\./ {print $3}' \
			"${S}")"
	SAR="${D}/${U}/db/$(hostname)/sysstat/sar"
	DISK="$(awk -F';' -v st="${START}" -v secs="${SECS}" -v dev="${VOLUME}" '
		NR > 1 && $4 == dev && $3 >= st && $3 < st + secs {
			n++; r += $6; w += $7; t += $5; u += $12; a += $11
		}
		END {
			if (n)
				printf "%.1f %.1f %.0f %.1f %.2f %.0f", r / n / 1024,
						w / n / 1024, t / n, u / n, a / n, r / n * secs
		}' "${SAR}/sar-blockdev.csv")"
	IOWAIT="$(awk -F';' -v st="${START}" -v secs="${SECS}" '
		NR == 1 { for (i = 1; i <= NF; i++) h[$i] = i; next }
		$h["CPU"] == "-1" && $h["timestamp"] >= st &&
				$h["timestamp"] < st + secs { n++; io += $h["%iowait"] }
		END { if (n) printf "%.1f", io / n }' "${SAR}/sar-cpu.csv")"
	PG="$(awk -F, -v st="${START}" -v secs="${SECS}" -v db="${DBNAME}" '
		$3 == db && $1 >= st && $1 < st + secs {
			if (!f) { f = $0 }
			l = $0
		}
		END {
			split(f, a, ","); split(l, b, ",")
			read = b[7] - a[7]; hit = b[8] - a[8]
			if (read + hit > 0)
				printf "%.1f %.0f", 100 * hit / (read + hit),
						read * 8 / 1024 / (b[1] - a[1])
		}' "${D}/${U}/db/$(hostname)/dbstat/pg_stat_database.csv")"
	# DISK: read MB/s, write MB/s, IOPS, util, await, read kB total.
	echo "${U} ${TRTPS} ${DISK} ${IOWAIT} ${PG} ${TR}" | awk '
		NF == 11 {
			printf "%s %s %s %s %s %s %s %s %s %s %.2f\n",
					$1, $2, $3, $4, $5, $6, $7, $9, $10, $11 / 1,
					$8 / 1024 / $12
		}
		NF == 12 {
			printf "%s %s %s %s %s %s %s %s %s %s %.2f\n",
					$1, $2, $3, $4, $5, $6, $7, $9, $10, $11,
					$8 / 1024 / $12
		}'
}

for C in $(ls -d "${RESULTS}"/c[0-9]*-u[0-9][0-9] 2> /dev/null |
		sed 's|.*/c\([0-9]*\)-u.*|\1|' | sort -nu); do
	echo
	echo "${C} customers:"
	echo
	{
		echo "Users trtps Read_MB/s Write_MB/s IOPS Util_% Await_ms" \
				"iowait_% PG_hit_% OS_req_MB/s Read_MB/TR"
		for D in "${RESULTS}/c${C}"-u[0-9][0-9]; do
			[ -d "${D}" ] && one_run "${D}"
		done | sort -n
	} | rst_table
done
exit 0
