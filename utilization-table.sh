#!/bin/sh
#
# Emit, per customer count, a reStructuredText table of how much of
# the machine's processing and storage resources each reportable run
# used, for RESULTS.rst.
#
# Usage: utilization-table.sh
#
# CPU_% is the processors' busy share, user plus system plus nice,
# over the measurement interval, and iowait_% the share they spent
# idle with I/O pending, which CPU_% does not include.  The storage
# columns compare the
# volume's operation rate and bandwidth from sar with the documented
# limits: the instance's EBS IOPS and bandwidth, and a gp3 member's
# baseline IOPS and throughput, the volume's traffic divided evenly
# over the members.  IO_% is the largest of the four, the one that
# would be reached first, and Limited_by names it.  sar's rates are
# what the kernel issued after merging, which for random 8 KiB reads is what
# EBS counts; its kB are KiB, so the instance's 10,000 Mbps is taken
# as 1192 MiB/s.  All limits are overridable from the environment if
# the volumes are provisioned above baseline.

. "$(dirname "$0")/env.sh"

VOLUME="${VOLUME:-vg_data-lv_stripe}"
MEMBERS="${MEMBERS:-26}"
INSTANCE_IOPS="${INSTANCE_IOPS:-43333}"
INSTANCE_MIBPS="${INSTANCE_MIBPS:-1192}"
MEMBER_IOPS="${MEMBER_IOPS:-3000}"
MEMBER_MIBPS="${MEMBER_MIBPS:-125}"

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
	SAR="${D}/${U}/db/$(hostname)/sysstat/sar"
	CPU="$(awk -F';' -v st="${START}" -v secs="${SECS}" '
		NR == 1 { for (i = 1; i <= NF; i++) h[$i] = i; next }
		$h["CPU"] == "-1" && $h["timestamp"] >= st &&
				$h["timestamp"] < st + secs {
			n++; b += $h["%user"] + $h["%nice"] + $h["%system"]
			w += $h["%iowait"]
		}
		END { if (n) printf "%.0f %.1f", b / n, w / n }' "${SAR}/sar-cpu.csv")"
	awk -F';' -v st="${START}" -v secs="${SECS}" -v dev="${VOLUME}" \
			-v u="${U}" -v trtps="${TRTPS}" -v cpu="${CPU% *}" \
			-v iow="${CPU#* }" \
			-v members="${MEMBERS}" -v iiops="${INSTANCE_IOPS}" \
			-v ibw="${INSTANCE_MIBPS}" -v miops="${MEMBER_IOPS}" \
			-v mbw="${MEMBER_MIBPS}" '
		NR > 1 && $4 == dev && $3 >= st && $3 < st + secs {
			n++; t += $5; bw += ($6 + $7) / 1024
		}
		END {
			if (!n)
				exit
			t /= n; bw /= n
			a = 100 * t / iiops
			b = 100 * bw / ibw
			c = 100 * t / members / miops
			d = 100 * bw / members / mbw
			io = a; limit = "instance_IOPS"
			if (b > io) { io = b; limit = "instance_MiB/s" }
			if (c > io) { io = c; limit = "member_IOPS" }
			if (d > io) { io = d; limit = "member_MiB/s" }
			printf "%s %s %s %s %.1f %.1f %.1f %.1f %.0f %s\n",
					u, trtps, cpu, iow, a, b, c, d, io, limit
		}' "${SAR}/sar-blockdev.csv"
}

for C in $(ls -d "${RESULTS}"/c[0-9]*-u[0-9][0-9] 2> /dev/null |
		sed 's|.*/c\([0-9]*\)-u.*|\1|' | sort -nu); do
	echo
	echo "${C} customers:"
	echo
	{
		echo "Users trtps CPU_% iowait_% inst_IOPS_% inst_BW_%" \
				"member_IOPS_% member_BW_% IO_% Limited_by"
		for D in "${RESULTS}/c${C}"-u[0-9][0-9]; do
			[ -d "${D}" ] && one_run "${D}"
		done | sort -n
	} | rst_table
done
exit 0
