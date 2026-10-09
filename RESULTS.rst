========================================
 DBT-5 customer and user sizing results
========================================

The results of the profiled customer and user sizing exercise.  The
method is ``PLAN.rst``, the steps it produced are ``JOURNAL.rst``,
the setup is described in ``README.rst``, the harness defects the
exercise found are in ``FIXES.rst``, and this file records what was
measured.  Throughput is stated in Trade Result transactions per
second, written ``trtps``, which is the quantity the specification
calls ``tpsE``.

**Updated 2026-09-15 18:30 UTC, 61 reportable runs.**

Answer
======

**32000 customers at 18 users, 62.45 trtps**, under the
specification's own rule, reported as measured.  Closed 2026-09-12
at 21:32 UTC and replicated twice on 2026-09-13.

31000 and 32000 are adjacent Load Units, the finest step the
specification allows, and they fall on opposite sides of the limit.
31000 reaches 65.42 trtps at 26 users against its line of 63.24,
102 percent of its nominal rate, and 32000 reaches at most 63.70,
at 32 users, against its line of 65.28.  32000 is therefore the
smallest legal customer count.  Its throughput is a plateau of
62.45 to 63.70 trtps from 18 to 32 users, every point of it below
the nominal 64.0, so the answer is reported as measured rather than
at the nominal rate, and the tie rule picks the lowest user count
within 3 percent of the best, 18 users.  16 users, the logical
processor count, falls 6 percent short of the best and is not a
tie.  "The strict rule" and phase 8 below have the measurements,
``throughput-crossing-default.png`` draws the four customer counts
around the crossing against their limit lines, and
``throughput-survey-default.png`` every customer count measured.

**Run to run scatter at the answer point.**  The point was measured
three times: once in the phase 8 sweep, seven and a half hours
after that database was built, and twice more afterwards on the
same database, the second replicate eleven and a half hours after
the build.  All three are valid and stable.

=============================  ========  ======  ========  ==========
Run                            Reported  Steady  Give ups  TR max (s)
=============================  ========  ======  ========  ==========
phase 8 sweep, 21:33 UTC          62.45   63.39        35        2.24
replicate 1, 00:20 UTC            62.57   63.56        22        1.60
replicate 2, 01:32 UTC            62.53   63.35        11        0.44
=============================  ========  ======  ========  ==========

The reported figures span 0.12 trtps, 0.2 percent, with a mean of
62.52 and a sample standard deviation of 0.06, 0.1 percent, and the
steady rates span 0.21 and average 63.43.  That is a tenth of the
2 percent scatter found at 30000 customers under the allowance,
and the rate did not rise from run to run, so the cache warming
that shaped the early runs of the phase 8 sweep had ended by the
time the 18 user point was measured.  The verdict does not depend
on which run is taken: every figure is between 51.2 and 64.0, under
the line and above the floor, and the two warm points at 31000,
65.02 and 65.42, are over its line by 2.8 and 3.4 percent, against
a scatter of a fraction of a percent.  The replicates are in
``runs/replicates/`` and are not in the tables below, which cover
one run per user count.

The answer under the 20 percent allowance
-----------------------------------------

What follows in this section is the answer under the 20 percent
allowance that the exercise ran under until 2026-09-11, kept as the
record of that part of the exercise.

**30000 customers at 24 users, 67.86 trtps**, against a ceiling of
72.0, ratio 0.94.  Closed 2026-09-10 at 13:59 UTC.

30000 is the smallest customer count the allowance permitted: it
reaches 67.86 trtps against a ceiling of 72.0, and the Load Unit
below it, probed on the basis of earlier measurements on this
machine rather than by the plan's rule, exceeded its ceiling at
every user count.  That probe
was set aside with the allowance, and its runs are in ``unused/``.

**Run to run scatter at the answer point.**  The answer point was
measured three times: once in the phase 2 sweep, four and a half
hours after that database was built, and twice more on a fresh
build of the same 30000 customers, as the first and second runs
after its smoke test.  All three are valid and stable.

=============================  ========  ======  ========  ==========
Run                            Reported  Steady  Give ups  TR max (s)
=============================  ========  ======  ========  ==========
phase 2 sweep, 03:27 UTC          67.86   68.87       267        1.89
replicate 1, 19:52 UTC            66.56   67.39       116        1.51
replicate 2, 20:54 UTC            66.81   67.69       101        1.95
=============================  ========  ======  ========  ==========

The reported figures span 1.30 trtps, 1.9 percent, with a mean of
67.08 and a sample standard deviation of 0.69, 1.0 percent.  The
steady rates span 1.48 and average 67.98.  That is the size of the
plan's "run to run scatter of a few percent", now measured at the
customer count that matters rather than assumed.  The sweep's run is
the highest of the three, and it is the one that ran last, on a
database four hours older than the replicates', which may account
for the difference, though three runs cannot establish that.

Two consequences.  The answer's rate is best stated as 67.86 trtps
reported, with a run to run spread of about 2 percent, and the
"under" verdict at 30000 does not depend on which of the three is
taken: the ceiling is 72.0 and the ratio is 0.92 to 0.94 for all of
them.  The replicates are in
``runs/replicates/`` and are not in the tables below, which cover
one run per user count.

Objective
=========

Maximize ``trtps(C, U)`` subject to ``trtps(C, U) <= 1.2 * C / 500``,
with ``C`` the customer count and ``U`` the emulated user count.  The
specification's own rule, clauses 6.6.8.2, 6.6.8.3 and 6.7.1.2 of
revision 1.14.0, sets the Scale Factor at 500 customers per tpsE and
accepts a measured rate only between 80 and 102 percent of ``C /
500``, reporting anything over 100 percent as ``C / 500``.  The 20
percent allowance over that was the user's, for the first part of
the exercise, and was withdrawn on 2026-09-11, see "The strict rule".
``PLAN.rst`` has the wording and the phases.

Phase 0 measures every user count from 1 to 32 at the smallest legal
``C``, 5000 customers, where the ceiling under the allowance is 12.0
trtps.  The machine exceeds that ceiling with a single user, so phase
0 cannot contain the answer.  It is the baseline from which the rest
of the exercise extrapolates: the peak rate with the whole database in
memory sets the customer count of the phase 1 spot check, and the
shape of throughput against concurrency, with a processor profile at
every point, is the reference against which every larger scale is
read.

System under test
=================

========================  ===========================================
Instance                  AWS r5b.4xlarge, us-west-2, EBS-optimized
Processors                16 logical, 8 cores with 2 threads each
Memory                    130405052 kB, 124 GiB
Storage                   26 gp3 volumes of 100 GiB in a 2.6 TB LVM
                          stripe, ``/perffarm``, data and write
                          ahead log together
Read-ahead                208 MB on the striped volume, 128 KB on
                          each member
Database                  PostgreSQL 18.4, built from source
shared_buffers            32 GB
effective_cache_size      40 GB
work_mem                  64 MB
effective_io_concurrency  300
random_page_cost          1.0
jit                       off
log_statement             none
max_connections           1000
checkpoint_timeout        15 min
DBT-5                     v0.10.14-1b8c1e0, branch
                          ``mee-deliver-concurrently``, AppImage
                          ``bin/dbt5``
Touchstone Tools          wip at 9d75d71
Stored functions          PL/C, verified after every rebuild
broker table              fill factor 10, see ``FIXES.rst``
Customers                 5000, 60 GB
Measurement interval      3600 s
Warmup                    60 s
Profile                   perf, 20 s at the middle of the interval
========================  ===========================================

The instance is an Amazon Web Services (AWS) r5b.4xlarge, and its
storage is 26 Elastic Block Store (EBS) volumes of the gp3 type,
combined by the Logical Volume Manager (LVM) into one striped
volume.  PostgreSQL's defaults are far from ideal for a workload
like this one, so the server settings above are rough starting
values from long-standing rules of thumb for sizing PostgreSQL, some
of them about 20 years old, which may or may not have been measured
recently.  They are not tuned values.  Statement, connection and
disconnection logging are off.  Nothing is changed during the
exercise.

A note on these runs and the specification's execution rules, so
that none is mistaken for a compliant measurement.  The 3600 second
interval spans at least four of the server's 15 minute checkpoints,
which is why it was chosen, and the checkpoint interval meets clause
6.6.5.3, but clause 6.6.5.1 requires a measurement interval of at
least two hours, so these are characterization intervals at half the
compliant minimum.  ``PLAN.rst`` has the wording.

Phase 0, 5000 customers
=======================

One row per reportable run.  ``Gain`` is the increase over the
previous user count.  ``TR_mix`` is Trade Result's share of the
transaction mix in percent, against 10.1 for Trade Order.  In a run
in which the market exchange delivers results as fast as they
arrive, the two are nearly equal.  ``TR_rb`` is the number of Trade
Results the Brokerage House gave up on after ten serialization
retries, which the summary counts as rollbacks.  ``TO_rb`` is the
Trade Order rollback rate in percent, which the specification puts
at about 1.  ``TR_max`` is the longest Trade Result response time in
seconds.  ``MEE_busy`` is the mean number of the market exchange
emulator's 16 connections to the Brokerage House in use, the
delivery rate multiplied by the delivery round trip time, from
``mee-load.sh``.  It shows how far the pool is from being fully
occupied, which is the condition under which deliveries limit
throughput, as they did before the market exchange fix described in
``FIXES.rst``.

The second table is what ``stability.sh`` reports for each run: the
reported rate, the mean over the settled part of the run, its
scatter, the counting floor that scatter is judged against, the
drift over the settled part in percent of the mean per hour, and how
long the run took to settle.

.. tables-begin

::

     CUSTOMERS BEST_TRTPS   CEILING  USERS  SECONDS   RATIO VERDICT  STABILITY
          5000     193.78      10.2     17     3600   19.00 over     stable
         30000      67.86      61.2     24     3600    1.11 over     stable
         31000      65.42      63.2     26     3600    1.03 over     stable
         32000      63.70      65.3     32     3600    0.98 under    stable
         35000      48.98      71.4     28     3600    0.69 under    periodic
         45000       4.62      91.8     16     3600    0.05 under    variable
         97000       1.98     197.9     16     3600    0.01 under    unstable,drifting
    
     CUSTOMERS   CEILING        u1        u2        u3        u4        u5        u6        u7        u8        u9       u10       u11       u12       u13       u14       u15       u16       u17       u18       u19       u20       u21       u22       u23       u24       u25       u26       u27       u28       u29       u30       u31       u32       u36       u40
          5000      10.2     21.71     42.90     63.26     82.98    100.85    115.66    126.31    136.07    146.08    156.79    166.82    176.68    185.46    190.74    192.66    193.59    193.78    193.63    190.16    192.04    192.74    192.10    188.93    190.87    190.10    188.79    188.19    186.92    186.22    184.81    183.64    183.21         -         -
         30000      61.2         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -     64.43         -     66.87         -     67.22         -     67.82         -     67.86         -     67.54         -     67.74         -         -         -     67.53     67.57     67.56
         31000      63.2         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -    19.59s         -         -         -         -         -     65.02         -     62.45         -     65.42         -         -         -         -         -         -         -         -
         32000      65.3         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -     59.65         -     62.45         -     62.69         -     60.07         -     63.52         -     61.69         -     63.56         -         -         -     63.70         -         -
         35000      71.4         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -    23.80s         -         -         -     48.23         -     47.29         -     48.29         -     47.65         -     48.98         -         -         -     48.30         -         -
         45000      91.8         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -      4.62         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -
         97000     197.9         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -      1.98         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -         -

=====  ======  =====  ======  =====  =====  ======  ========
Users   trtps   Gain  TR_mix  TR_rb  TO_rb  TR_max  MEE_busy
=====  ======  =====  ======  =====  =====  ======  ========
    1   21.71      -   9.873      0   0.99    0.07      0.05
    2   42.90  21.19   9.869      0   1.02    0.03      0.10
    3   63.26  20.36   9.867      0   1.01    0.02      0.16
    4   82.98  19.72   9.868      0   1.00    0.03      0.21
    5  100.85  17.87   9.868      0   0.99    0.08      0.27
    6  115.66  14.81   9.874      0   0.96    0.07      0.32
    7  126.31  10.65   9.869      1   0.98    0.05      0.36
    8  136.07   9.76   9.866      0   1.00    0.05      0.39
    9  146.08  10.01   9.869      1   0.98    0.10      0.43
   10  156.79  10.71   9.870      1   0.99    0.07      0.47
   11  166.82  10.03   9.867      2   1.01    0.08      0.52
   12  176.68   9.86   9.869      1   0.96    0.07      0.61
   13  185.46   8.78   9.868      5   0.98    0.09      0.77
   14  190.74   5.28   9.867     10   1.00    0.10      1.05
   15  192.66   1.92   9.866     26   0.99    0.10      1.44
   16  193.59   0.93   9.870     43   0.98    0.10      0.01
   17  193.78   0.19   9.867     35   1.01    0.10      1.54
   18  193.63  -0.15   9.869     49   1.01    0.12      1.57
   19  190.16  -3.47   9.866     70   1.00    0.10      1.57
   20  192.04   1.88   9.868     70   1.01    0.11      1.62
   21  192.74   0.70   9.873    513   0.96    0.13      1.71
   22  192.10  -0.64   9.870     89   1.00    0.13      1.68
   23  188.93  -3.17   9.871   1005   0.99    0.20      1.84
   24  190.87   1.94   9.868    100   1.00    0.14      1.75
   25  190.10  -0.77   9.871    126   0.98    0.17      1.80
   26  188.79  -1.31   9.871    146   0.98    0.24      1.86
   27  188.19  -0.60   9.871    164   1.00    0.22      1.91
   28  186.92  -1.27   9.873    218   0.99    0.20      1.97
   29  186.22  -0.70   9.873    231   1.00    0.25      2.04
   30  184.81  -1.41   9.871    229   1.00    0.19      2.11
   31  183.64  -1.17   9.875    273   0.99    0.28      2.16
   32  183.21  -0.43   9.870    277   1.00    0.24      2.20
=====  ======  =====  ======  =====  =====  ======  ========

=============  ========  ======  =====  =====  =======  =====  =================
Run            Reported  Steady     CV  Noise  Drift/h   Ramp  Verdict
=============  ========  ======  =====  =====  =======  =====  =================
c5000-u01/1       21.71   21.97   2.0%   2.8%    -0.2%   420s  stable
c5000-u02/2       42.90   43.49   1.5%   2.0%     1.2%   480s  stable
c5000-u03/3       63.26   64.27   1.5%   1.6%     2.7%   540s  stable
c5000-u04/4       82.98   84.17   1.1%   1.4%     1.1%   480s  stable
c5000-u05/5      100.85  102.17   1.4%   1.3%     2.6%   420s  stable
c5000-u06/6      115.66  117.00   1.3%   1.2%     1.6%   360s  stable
c5000-u07/7      126.31  127.94   1.0%   1.1%     1.2%   420s  stable
c5000-u08/8      136.07  137.62   1.2%   1.1%     0.9%   360s  stable
c5000-u09/9      146.08  148.19   1.0%   1.1%     1.2%   480s  stable
c5000-u10/10     156.79  158.71   1.1%   1.0%     0.2%   420s  stable
c5000-u11/11     166.82  168.76   1.2%   1.0%     1.6%   360s  stable
c5000-u12/12     176.68  178.68   1.2%   1.0%     1.4%   360s  stable
c5000-u13/13     185.46  187.75   1.1%   0.9%     0.8%   420s  stable
c5000-u14/14     190.74  193.23   1.0%   0.9%     0.2%   420s  stable
c5000-u15/15     192.66  194.95   1.3%   0.9%     0.7%   360s  stable
c5000-u16/16     193.59  195.66   1.0%   0.9%     1.2%   360s  stable
c5000-u17/17     193.78  195.93   1.1%   0.9%     1.1%   360s  stable
c5000-u18/18     193.63  195.98   0.9%   0.9%     0.8%   420s  stable
c5000-u19/19     190.16  195.93   0.6%   0.9%     0.6%   900s  stable
c5000-u20/20     192.04  194.36   1.1%   0.9%     1.8%   420s  stable
c5000-u21/21     192.74  195.67   1.1%   0.9%     1.6%   480s  stable
c5000-u22/22     192.10  194.27   1.1%   0.9%     2.3%   360s  stable
c5000-u23/23     188.93  190.63   1.7%   0.9%     1.6%   300s  stable
c5000-u24/24     190.87  193.55   1.1%   0.9%     0.9%   420s  stable
c5000-u25/25     190.10  192.30   1.3%   0.9%     1.2%   360s  stable
c5000-u26/26     188.79  191.24   0.9%   0.9%     0.3%   480s  stable
c5000-u27/27     188.19  190.27   1.3%   0.9%     0.3%   360s  stable
c5000-u28/28     186.92  189.01   1.2%   0.9%     1.6%   360s  stable
c5000-u29/29     186.22  188.29   1.1%   0.9%     1.5%   360s  stable
c5000-u30/30     184.81  186.89   1.2%   0.9%     1.1%   360s  stable
c5000-u31/31     183.64  185.61   1.4%   0.9%     0.0%   360s  stable
c5000-u32/32     183.21  185.53   1.0%   0.9%     1.3%   420s  stable
c30000-u16/16     64.43   65.29   1.7%   1.6%     2.3%   420s  stable
c30000-u18/18     66.87   67.93   1.9%   1.6%    -0.3%   720s  stable
c30000-u20/20     67.22   68.10   2.4%   1.6%     2.6%   420s  stable
c30000-u22/22     67.82   68.74   1.8%   1.6%     2.6%   420s  stable
c30000-u24/24     67.86   68.87   1.9%   1.6%     0.7%   480s  stable
c30000-u26/26     67.54   68.77   1.9%   1.6%    -0.3%   600s  stable
c30000-u28/28     67.74   68.75   2.0%   1.6%     1.0%   480s  stable
c30000-u32/32     67.53   68.51   1.8%   1.6%     2.0%   420s  stable
c30000-u36/36     67.57   68.63   2.0%   1.6%     0.7%   480s  stable
c30000-u40/40     67.56   68.72   1.6%   1.6%    -1.1%   720s  stable
c31000-u22/22     65.02   66.06   2.3%   1.6%     1.1%   660s  stable
c31000-u24/24     62.45   65.07   4.4%   1.6%     1.9%   480s  variable
c31000-u26/26     65.42   66.41   2.2%   1.6%     2.4%   480s  stable
c32000-u16/16     59.65   60.67   3.0%   1.7%     0.7%  1380s  stable
c32000-u18/18     62.45   63.39   3.0%   1.6%     0.1%   600s  stable
c32000-u20/20     62.69   63.70   2.7%   1.6%     0.9%   960s  stable
c32000-u22/22     60.07   61.39   1.7%   0.7%     3.2%   600s  periodic
c32000-u24/24     63.52   64.52   2.4%   1.6%    -0.4%   540s  stable
c32000-u26/26     61.69   62.24   1.9%   0.7%     3.4%     0s  periodic
c32000-u28/28     63.56   64.57   2.7%   1.6%     0.9%   600s  stable
c32000-u32/32     63.70   64.69   2.3%   1.6%     1.3%   480s  stable
c35000-u20/20     48.23   48.66  15.9%   1.9%    -0.6%     0s  unstable
c35000-u22/22     47.29   48.73   2.9%   0.8%     2.2%  1500s  periodic
c35000-u24/24     48.29   48.77  16.4%   1.8%     1.7%     0s  unstable
c35000-u26/26     47.65   48.94   1.8%   0.8%    -1.7%  1200s  periodic
c35000-u28/28     48.98   49.67   1.7%   0.8%    -0.6%   600s  periodic
c35000-u32/32     48.30   48.81   2.5%   0.8%     3.0%     0s  periodic
c45000-u16/16      4.62    4.67   6.9%   6.0%     1.6%   240s  variable
c97000-u16/16      1.98    2.01  11.6%   9.1%    10.1%   360s  unstable,drifting
=============  ========  ======  =====  =====  =======  =====  =================

.. tables-end

What phase 0 shows
==================

**The optimum is 16 users, 193.59 trtps**, with a steady rate of
195.2 once the run had settled.  The highest single figure is 193.78
at 17 users, with 18 at 193.63, but the three are within 0.1 percent
of one another, far inside the 3 percent the plan treats as a tie,
and the tie rule prefers the lower user count.  16 is also the
machine's logical processor count.  The peak is on a plateau: every
point from 16 to 22 users reports between 192.0 and 193.8, within
the scatter of one another.  Beyond 22 users throughput declines
slowly, to 183.21 at 32, 5 percent under the peak.  The edge rule is
satisfied, since the best point is interior and 32 users is well
below it, so the sweep was not extended.

**Three regimes, and the processor topology explains the boundaries
between them.**  The machine has 8 cores with 2 hardware threads
each, 16 logical processors.  Mean processor time over each
measurement interval, from ``sar``, the system activity reporter:

=====  =====  =====  ======  ======  ======
Users  trtps  user   system  iowait  idle
=====  =====  =====  ======  ======  ======
    1   21.7    9.5     2.7     0.7    87.1
    4   83.0   27.5     4.3     2.3    65.9
    7  126.3   45.8     5.5     3.1    45.6
    8  136.1   52.0     5.8     3.2    38.9
   12  176.7   76.4     7.0     3.1    13.4
   16  193.6   90.5     7.1     0.8     1.7
   17  193.8   91.2     6.9     0.6     1.3
   22  192.1   93.2     6.0     0.2     0.6
   32  183.2   94.9     4.9     0.0     0.1
=====  =====  =====  ======  ======  ======

Busy, here and everywhere below, means user plus system time.  Wait
on input/output (I/O) is always stated separately, and idle is what
remains.  From 1 to 4 users throughput rises by 20 to 21 trtps per
added user and each user takes about 13 percent of the machine,
about the work of two logical processors between its backend and the
harness.  The gain per user halves between 5 and 7 users, where the
machine passes 50 percent busy, which is the point at which every
physical core has a thread on it.  From 7 to 13 users the gain holds
at about 10 per user, the second hardware thread of each core adding
about half of what the core itself added.  It falls to zero between
14 and 16 users, where idle time reaches 2 percent, and the plateau
is the processor at saturation.  The database is in memory
throughout: I/O wait never exceeds 3.3 percent and is zero on the
plateau.

**What the processor is doing on the plateau.**  The 20 second
profile at the middle of each interval attributes 85 percent of
samples to postgres at 16 users and 91 percent at 32, against 23
percent at 4 users, where 68 percent of samples are the idle loop.
The symbols with the largest shares at 16 and 32 users, as percent
of all samples:

============================  =====  =====
Symbol                           16     32
============================  =====  =====
hash_search_with_hash_value    10.2   11.4
heap_page_prune_opt             7.3    8.0
heap_hot_search_buffer          5.7    6.2
PinBuffer                       5.5    6.2
ExecInterpExpr                  4.5    5.0
fill_val                        3.3    3.4
LWLockAttemptLock               3.1    3.6
tts_buffer_heap_getsomeattrs    2.8    2.8
============================  =====  =====

Buffer lookup and pinning, and the pruning and following of heap
only tuple (HOT) chains on heavily updated pages, are the largest
items in the profile: the cost of an in-memory workload of small
transactions that update the same rows repeatedly.

**The decline past 22 users is contention, and it is mild.**  Lock
acquisition rises from 3.2 to 3.6 percent of samples, Trade Results
that the Brokerage House gives up on after ten serialization retries
rise from a few per hour at 12 users to about 280 at 32, still 0.04
percent of Trade Results, and the longest Trade Result response time
grows from 0.1 to 0.28 seconds.  Every point is far inside the
specification's response time constraints, 2 seconds at the 90th
percentile for Trade Result.

**Every run is valid and settled.**  Trade Result is 9.87 percent of
the mix in every run, against 10.12 for Trade Order, so the market
exchange delivered results as fast as they arrived at every user
count, and its connection pool was never more than 2.2 of 16
connections busy on average.  Trade Order rollbacks are 1.0 percent.
Scatter over the settled part of each run is at the counting floor,
drift is under 3 percent per hour, and every run settles within 5 to
9 minutes except the 19 user point, which took 15 minutes and
therefore reports 190.16 for a steady rate equal to its neighbors'.
The reported figures include those minutes and understate steady
state by 1 to 3 percent.

**The spot check.**  The peak rate requires ``193.59 * 500 = 96795``
customers under the strict rule, rounded up to the next Load Unit:
97000 customers, about 1.16 TB.  The 17 user figure gives the same
count.  Its build started at 12:34 UTC on 2026-09-09.

Phase 1, spot check at 97000 customers
======================================

**Under, by a factor of 118.**  One point, 16 users, 3600 seconds:
1.98 trtps against a ceiling of 232.8.  The run is valid, with Trade
Result at 9.91 percent of the mix against 10.16 for Trade Order and
no Trade Results given up on, and it is limited by storage: 83
percent I/O wait, 9 percent idle, 4 percent user time, on a 1170 GB
database against 124 GiB of memory.  The stability check reports it
as unstable and drifting, but at 2 trtps the counting floor is 9
percent and the scatter is 12, so that is noise, and no reading of
it changes a verdict that is under by two orders of magnitude.  No
second point was needed.

The build took 6 hours 52 minutes: 94 minutes of loading, the rest
indexes, constraints and a final analyze.  It was started twice.  The
first start was killed by the session harness five minutes after it
began, because the harness judged the machine low on memory while 87
GB of 124 was available.  Only free memory was low, because twenty
loaders were filling the page cache.  The second start ran detached
from the harness and completed.  A smoke test that briefly ran
against the half loaded database in between is kept as
``unused/c97000-smoke.invalid-partial-db``, and ``phase.sh`` now
checks
that the C stored functions are present before it accepts a database
as built.

So the bracket is 5000 over and 97000 under.

Phase 2, 30000 customers
========================

**Under, ratio 0.94.**  Ten points measured, all under the 72.0
ceiling, every one valid and stable:

=====  ======  ==========
Users   trtps  Ratio
=====  ======  ==========
   16   64.43  0.89
   18   66.87  0.93
   20   67.22  0.93
   22   67.82  0.94
   24   67.86  0.94
   26   67.54  0.94
   28   67.74  0.94
   32   67.53  0.94
   36   67.57  0.94
   40   67.56  0.94
=====  ======  ==========

Above 20 users the rate holds a plateau from 22 to 40 users within
0.35 trtps.  Steady rates over the settled parts of the runs are
68.5 to 68.9 across that plateau.

The best point, 67.86 at 24 users, is interior.  Every later point
ties it within 0.5 percent, and the plan's tie rule required the
range to be extended, which it was, from 24 to 40 users in four
steps.  Ten points across an 18 user range show that the top is flat
rather than the rising side of a higher peak, and the ceiling is 6
percent above it, twelve times the plateau's scatter.  The phase is
closed as "under" on that basis, without measuring beyond 40 users.

The machine at this scale is 83 to 94 percent busy in user and
system time, the higher figure at the higher user counts, with a
further 4 to 14 percent waiting on I/O, so it is near processor
saturation even with a 362 GB database against 124 GiB of memory,
and a quarter of its time is system time, the cost of reading
through the page cache.  Trade Results given up on number up to 324
per run, 0.1 percent, and the longest Trade Result response time is
under 2.5 seconds against a 2 second constraint on the 90th
percentile.

The bracket is 5000 over, 30000 under.

**How this probe was chosen, and what the plan would have chosen.**
The plan interpolates the margin between the bracket ends: +181.8 at
5000 and -230.8 at 97000 put the crossing near 45500, so the plan's
next probe is 45000.  It was not taken.  Instead 30000 was probed on
the basis of earlier measurements on this machine, which placed the
crossing there.  That departed from the plan, and the user pointed
it out.  It reaches the same pair, since 45000 would have come back
far under and the interpolation from its margin would have named
30000 next, but the exercise then does not narrow on its own
measurements, and the survey lacks the point between 30000
and 97000 where throughput collapses.  Phase 4 below fills that in
after the fact, at 45000, and phase 6 at 35000.

The strict rule
===============

On 2026-09-11 the user withdrew the 20 percent allowance: guiding
the exercise with a looser rule than the specification's had made its
result harder to read, since the count that was under the allowance
was over the specification's limit.  From that point the rule is
clause 6.7.1.2 as written: a measured rate is accepted only between
80 and 102 percent of ``customers / 500``, and one between 100 and
102 percent is reported as the nominal.  ``env.sh`` now carries a
margin of 1.02, so the verdict column of ``collect.sh`` and the
tables below follow the strict rule, and the earlier verdicts are
reproduced with ``CEILING_MARGIN=1.2``.  The probe at the Load Unit
below 30000, taken on the basis of earlier measurements rather than
by the plan's rule, is set aside from the same date, and its runs are
in ``unused/``.

Every measured point, restated:

=========  ==============  ========  =======
Customers  Strict window   Measured  Verdict
=========  ==============  ========  =======
     5000    8.0 to  10.2    193.78  over
    30000   48.0 to  61.2     67.86  over
    31000   49.6 to 63.24     65.42  over
    32000   51.2 to 65.28     63.70  under
    35000   56.0 to  71.4     48.98  under
    45000   72.0 to  91.8      4.62  under
    97000  155.2 to 197.9      1.98  under
=========  ==============  ========  =======

The plan keeps to the 5000 grid until the bracket is one step wide,
and 35000, the grid point above the over end, was measured as phase
6 below.  It came back under its 71.4 line, and below the 56.0
floor as well, so 35000 customers could not be reported at all,
and the bracket became 30000 over, 35000 under.  Interpolating the
margins against the 102 percent line, plus 6.66 at 30000 and minus
22.42 at 35000, put the crossing at 31145 customers, so the next
probe was 31000, with a strict window of 49.6 to 63.24 and a
nominal rate of 62.0.  It came back over on its second point, as
phase 7 below records, so the bracket became 31000 over, 35000
under, and the next probe was 32000, the Load Unit above the over
end, with a strict window of 51.2 to 65.28 and a nominal rate of
64.0.  It came back under at every user count, as phase 8 below
records.  31000 over and 32000 under are adjacent Load Units, so
the bisection is closed and 32000 is the answer.  The answer is
reported at its nominal rate if
its measured rate lies between the nominal and the 102 percent
line, and as measured if it lies between 80 and 100 percent of the
nominal.

Phase 6, 35000 customers
========================

**Under, ratio 0.69, and below the validity floor.**  Six user
counts were measured: 24, 22, 26, 20 and 28, then 32 by the edge
rule, and 24 again on a warm cache.  Every point is below the 71.4
line and below the 56.0 floor that clause 6.7.1.2 sets at 80
percent of nominal, so 35000 customers is not only under but could
not be reported at all:

=====  ======  ======  ==========
Users   trtps  Steady  Ratio
=====  ======  ======  ==========
   20   48.23   48.66  0.68
   22   47.29   48.85  0.66
   24   48.29   48.77  0.68
   26   47.65   48.13  0.67
   28   48.98   49.39  0.69
   32   48.30   48.81  0.68
=====  ======  ======  ==========

The six points are within 3.6 percent of one another, a plateau
like the one at 30000.  The best, 48.98 at 28 users, was at the
highest user count measured until 32 users reported 1.4 percent
less, so the peak is interior and the edge rule is satisfied.  By
the tie rule the user count reported for this scale would be 20,
the lowest of the counts within 3 percent of the best, but nothing
at this scale can be reported.  The market exchange delivered
results as fast as they arrived in every run, with Trade Result at
9.85 to 9.88 percent of the mix against 10.11 to 10.12 for Trade
Order.  Trade Results given up on were 0 to 10 per run, Trade Order
rollbacks 0.9 to 1.0 percent, and the longest Trade Result response
time 0.17 to 0.43 seconds.  The build took 131 minutes and the
database is 420 GB.  The phase closed at 06:08 UTC on 2026-09-12,
and the next probe, 31000, is phase 7 below.

**The first point never settled and was set aside.**  The 24 user
run was the first after the build, and the 600 second smoke test
had not warmed the cache.  Its rate climbed from 26 to 46 trtps
over the first thirty minutes, then held between 40 and 45, and it
reported 39.89.  The plan does not let a never settled run decide
anything, so the run is kept as
``unused/c35000-u24.invalid-cold-cache``,
excluded from the tables, and 24 users was repeated as the last run
of the phase.  The repeat, on the warm cache, settled at once and
reported 48.29.

**Throughput at this scale alternates minute by minute.**  Every
settled run at 35000 alternates between a fast minute and a slow
minute for the whole hour.  At 22 users the Trade Result rate is
about 55 per second in one minute and 40 in the next, the
processors' I/O wait is 12 percent and then 38, and their busy
share is 85 percent and then 60.  On one minute bins the stability
check reads every run as unstable, with a scatter of 9 to 16
percent against a counting floor of 2, and it is correct that the
runs are not steady from minute to minute.  The hour long mean is
still the steady rate, because each run spans about thirty cycles
and the cycle is a property of the system at this scale, present
in every run, rather than run to run noise.  The check therefore
judges such a run again on five minute bins, longer than the
cycle, and reports it as periodic when it is stable on those: four
of the six runs here are within 3 percent on five minute bins, and
the 20 and 24 user runs, at 5.3 and 3.7 percent, stay marked
unstable because the cycle in them is less regular.  The per
minute statistics locate the cause:

* The volume's read traffic is steady at about 380 MB/s, checkpoints
  occur every 15 minutes as timed, none was requested by write
  ahead log volume, and no autovacuum or write burst coincides with
  the slow minutes.
* What alternates is the page cache hit ratio.  PostgreSQL's block
  reads from the operating system alternate between 670 thousand
  and 450 thousand per second at the same disk traffic, while its
  own buffer cache hit ratio holds at 53 percent, so a slow minute
  is a minute in which more of those reads miss the page cache and
  go to disk.
* The kernel's file cache accounting alternates with it.  The
  active list is 5 to 30 GB in one minute and 63 to 89 GB in the
  next.  The kernel's multi-generational least recently used list
  is enabled (``/sys/kernel/mm/lru_gen/enabled`` reads 0x0007), and
  its generation aging produces that sawtooth.  At 30000 customers
  the same sawtooth is present in the active list, but the read
  rate and the throughput stay smooth.  At 35000 the working set is
  far enough beyond memory that each aging step costs a minute of
  extra misses before the hit ratio recovers.

Averaged over a run the machine is about 73 percent busy in user and
system time with 25 percent I/O wait.  The processors wait a
quarter of the time, and the disk is not saturated, since each
request still waits under a millisecond, so at this scale the limit
is the page cache's behavior rather than the device.

One setting of the system under test belongs here.  The striped
volume's read-ahead is 208 MB, ``read_ahead_kb`` 212992 on the
device mapper device, set by the volume manager when the striped
volume was created, against 128 KB on each member.  It has been the
same for every run, and nothing is changed during the exercise,
but a random 8 KB read workload on a device with a 208 MB
read-ahead window bears on the read-ahead effect noted at 97000
customers in the storage section.

Phase 7, 31000 customers
========================

**Over, conclusive from the second point.**  The strict window is
49.6 to 63.24 with a nominal rate of 62.0.  The first point, 24
users, was the first run after the build and reported 62.45, under
the line by the reported figure, but it settled after eight minutes
at a steady rate of 65.07, over the line.  Its first ten minutes
ran on the cold cache at 38 and then 60 trtps, and those minutes
pulled the hour's figure below the line.  The second point, 22
users, ran on the warm cache and reported 65.02, steady 66.06,
stable, which is over the 63.24 line by 2.8 percent.  An over
verdict is conclusive from one point, so the phase was stopped
after it.  The 26 user point, already running, was allowed to
finish, reported 65.42, stable, over as well, and no further point
was started.

=====  ======  ======  ==========
Users   trtps  Steady  Ratio
=====  ======  ======  ==========
   22   65.02   66.06  1.03
   24   62.45   65.07  0.99
   26   65.42   66.41  1.03
=====  ======  ======  ==========

All three runs are valid.  Trade Result is 9.86 to 9.87 percent of
the mix against 10.12 for Trade Order, Trade Results given up on
were 122 in the cold run and 40 and 72 in the warm ones, Trade
Order rollbacks are 1.0 percent, and the longest Trade Result
response time is 1.57 to 2.48 seconds.  The build took 118 minutes
and the database is 374 GB.

The cold cache matters more here than at 35000, because the verdict
is close.  The reported figure of a run whose first minutes ran on
a cold cache understates the steady rate by 4 percent at this
scale, and 4 percent is the whole margin between 62.45 and 65.07.
The plan judges by the reported figure of a settled run, and by
that rule the 24 user run alone would have put 31000 under.  The
warm run decided it, and the verdict rests on the warm run, on the
24 user run's steady rate, and on the throughput at 30000 and
35000, all of which agree.

The bracket is 31000 over, 35000 under.  The next probe is 32000,
the Load Unit above the over end, with a strict window of 51.2 to
65.28 and a nominal rate of 64.0.  If 32000 is under, it is
adjacent to 31000 and the bisection closes with 32000 as the
answer.

Phase 8, 32000 customers
========================

**Under at every user count, and the bisection is closed.**  The
strict window is 51.2 to 65.28 with a nominal rate of 64.0.  Eight
warm cache points were measured, all under the line and above the
floor:

=====  ======  ======  ==========
Users   trtps  Steady  Ratio
=====  ======  ======  ==========
   16   59.65   60.67  0.91
   18   62.45   63.39  0.96
   20   62.69   63.70  0.96
   22   60.07   61.39  0.92
   24   63.52   64.52  0.97
   26   61.69   62.24  0.95
   28   63.56   64.57  0.97
   32   63.70   64.69  0.98
=====  ======  ======  ==========

The first point, 24 users, was the first run after the build, and
the 600 second smoke test had not warmed the 387 GB database.  Its
rate climbed for the whole hour, from 19 to 58 trtps, and it
reported 47.54 without settling.  It is kept as
``unused/c32000-u24.invalid-cold-cache``, and 24 users is repeated
at the
end of the phase, as the plan requires.

The cache kept warming through the phase.  The runs were measured
in the order 22, 26, 20, 28, and their reported rates rise in that
order, 60.07, 61.69, 62.69, 63.56, while the drift within each run
falls from 3.2 percent per hour to 0.9.  The first two warm runs
therefore understate the rate this scale sustains once the cache
has settled, and the order of the user counts is confounded with
the warming.  The 32 user point and the 24 user repeat, the sixth
and seventh runs, show that the rise had stopped: their steady
rates, 64.69 and 64.52, match the 28 user run's 64.57, and their
drift is under 1.5 percent per hour.

The best point, 63.56 at 28 users, was at the edge of the range
measured, so the edge rule required 32 users, as at 35000.  32
users reported 63.70, 0.2 percent above 28, and the three runs from
24 to 32 users are within 0.3 percent of one another, so the top is
flat and the phase is closed without measuring 36.  The runs
alternate minute by minute as at 35000.  The stability check reads
the 22 and 26 user runs as periodic, settled within ten minutes on
five minute bins, and the other four as stable.  All six are valid:
Trade Result at 9.87 percent of the mix against 10.12 for Trade
Order, 64 to 130 Trade Results given up on per run, Trade Order
rollbacks 1.0 percent, and the longest Trade Result response time
2.0 to 2.4 seconds.  The build took 118 minutes.

**The verdict closes the bisection.**  32000 is under and valid, 31000
is over, and they are adjacent Load Units, so 32000 customers is
the smallest legal count and the answer.  Every point lies below
the nominal 64.0, so the answer is reported as measured rather
than at the nominal rate.  Which user count is reported follows
the tie rule: the points within 3 percent of the best, 63.70 at 32
users, are 20, 24, 28 and 32, and the rule prefers the lowest of
them.  20 users was also the lowest count measured, so the rule was
applied at that edge: 18 users reported 62.45, stable, 2 percent
below the best, so it ties and becomes the reported count, and 16
users, the logical processor count, reported 59.65, 6 percent below
the best and outside the tie band.  The reported point is therefore
32000 customers at 18 users, 62.45 trtps.  The two replicate runs
the plan requires at that point, 62.57 and 62.53, are in the
Answer section.

Phase 4, the bisection redone by the plan's rule
=================================================

After the bisection had closed, the user asked that it be redone
the way the plan prescribes, from this exercise's own measurements
alone and without the earlier measurements that had placed the
30000 probe, so that the survey narrows on its own measurements.  The plan
interpolates the margin, throughput minus ceiling, between the
bracket ends: +181.78 at 5000 and -230.82 at 97000 put the crossing
near 45500, so the plan's first bisection probe is 45000.

A phase at 35000 was started first, on 2026-09-11 at 15:29 UTC, and
stopped twenty minutes into its build when the user chose to take
45000 first.  Nothing was measured at 35000, and its logs are kept
in ``logs/`` and ``build/`` with an ``aborted`` suffix.

**45000 customers: under, by a factor of 23.**  One point, 16 users,
3600 seconds, 4.62 trtps against a ceiling of 108.0, ratio 0.04.
The run is valid, with Trade Result at 9.89 percent of the mix
against 10.11 for Trade Order and no Trade Results given up on, and
it is limited by storage: 78 percent I/O wait, 8 percent idle, 6
percent user time, on a 540 GB database against 124 GiB of memory.
The stability check reports "variable", which at 4.6 trtps is the
counting floor of 6 percent against a scatter of 7, and changes
nothing.  No second point was needed, since the margin is a factor
of 23 rather than two.  The build took 170 minutes.

**The rule then selects 30000.**  Interpolating the margin between
+181.78 at 5000 and -103.38 at 45000 puts the crossing at 30499,
which rounds to 30000 on the grid.  This exercise had measured 30000
ten times, all under the allowance ceiling, and the Load Unit below
it over, so the bisection under the allowance closed on those
measurements without another build.  The sequence the plan produces
from this exercise's own data is therefore 5000, 97000, 45000, 30000,
and it ends at the same answer.
Where the earlier account had taken 30000 on the basis of earlier
measurements, the survey now narrows on what this exercise measured, and it has
the point that shows the collapse between 30000 and 97000: 4.62
trtps at 45000, where the database is more than four times memory,
against 67.86 at 30000, three times.

Storage across the scales
=========================

The same ``sar`` capture that gave the processor split also records
the database volume, a 26 way LVM stripe of 100 GB volumes that the
instance presents as NVMe (Non-Volatile Memory Express) devices, and
``pg_stat_database`` records the buffer cache's hits and misses.
One row per reportable run, over its measurement interval, generated
by ``io-table.sh``.  ``Read`` and ``Write`` are the volume's traffic
in MB/s and ``IOPS`` its input/output operations per second.
``Util`` is the share of time the volume had any request
outstanding, which on a 26 way stripe measures how continuously busy
it is, not how close to its limit.  ``Await`` is the mean time a
request waited, which does measure that.  ``iowait`` is the
processors' share of time idle with I/O pending.  ``PG_hit`` is the
share of block requests satisfied in ``shared_buffers``, ``OS_req``
the rate at which PostgreSQL asked the operating system for the
blocks it missed, and ``Read_MB/TR`` the volume's reads divided by
Trade Results completed.

How the hit ratios are computed.  ``PG_hit`` comes from the ``dbt5``
row of ``pg_stat_database``, which the statistics collector sampled
every minute: the difference in ``blks_hit`` and ``blks_read``
between the first and the last sample inside the measurement
interval, and ``PG_hit = blks_hit / (blks_hit + blks_read)``.
``blks_read`` counts blocks PostgreSQL had to ask the operating
system for, whether the page cache or the disk then supplied them,
so this is the buffer cache's hit ratio alone, and ``OS_req`` is the
same ``blks_read`` difference multiplied by 8 KiB per second.  The
page cache's share, quoted in the text as about 96 percent at 30000
customers, is not measured but derived: one minus the volume's read
bytes divided by ``OS_req``, both over the same interval.  Its
accuracy depends on that comparison, and where the kernel reads
ahead more than PostgreSQL asked for, as it does at 97000 customers,
it comes out negative and is not quoted.

.. io-tables-begin

5000 customers:

=====  ======  =========  ==========  ====  ======  ========  ========  ========  ===========  ==========
Users   trtps  Read_MB/s  Write_MB/s  IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  ======  =========  ==========  ====  ======  ========  ========  ========  ===========  ==========
    1   21.71        0.7         4.9   355    12.1      0.97       0.7      99.9            4        0.03
    2   42.90        1.4         6.2   484    21.1      0.94       1.3      99.9            8        0.03
    3   63.26        1.8         8.4   673    29.4      0.93       1.8      99.9           12        0.03
    4   82.98        1.9        10.4   824    36.7      0.94       2.3      99.9           16        0.02
    5  100.85        2.5        12.0   952    42.4      0.96       2.6      99.9           19        0.02
    6  115.66        1.2        13.2  1013    47.1      0.94       2.9      99.9           22        0.01
    7  126.31        1.6        14.0  1104    50.9      0.94       3.1      99.9           24        0.01
    8  136.07        2.0        14.8  1155    53.2      0.97       3.2      99.9           27        0.01
    9  146.08        0.6        15.5  1161    55.9      0.96       3.3      99.9           29        0.00
   10  156.79        0.8        16.3  1251    58.8      0.95       3.3      99.9           32        0.01
   11  166.82        0.6        17.0  1285    61.0      0.96       3.2      99.9           34        0.00
   12  176.68        1.0        17.6  1363    63.1      0.96       3.1      99.9           36        0.01
   13  185.46        1.5        18.0  1405    63.6      0.96       3.1      99.9           39        0.01
   14  190.74        0.6        17.9  1340    60.7      0.94       2.2      99.9           40        0.00
   15  192.66        0.5        18.0  1307    55.2      0.90       1.2      99.9           41        0.00
   16  193.59        1.0        18.1  1328    53.3      0.88       0.8      99.9           42        0.01
   17  193.78        1.6        18.0  1362    52.1      0.88       0.6      99.9           43        0.01
   18  193.63        0.8        17.9  1307    50.8      0.86       0.4      99.9           43        0.00
   19  190.16        0.7        17.7  1297    49.5      0.85       0.3      99.9           43        0.00
   20  192.04        1.1        17.7  1319    49.4      0.84       0.3      99.9           44        0.01
   21  192.74        1.3        32.1  1429    51.2      0.91       0.3      99.9           45        0.01
   22  192.10        1.8        18.3  1386    49.3      0.82       0.2      99.9           45        0.01
   23  188.93       23.6        50.1  2050    55.1      1.13       0.2      99.9           44        0.13
   24  190.87        6.0        17.8  1709    50.1      0.75       0.2      99.9           45        0.03
   25  190.10        2.8        17.7  1430    48.2      0.77       0.1      99.9           45        0.01
   26  188.79        4.8        19.8  1513    48.2      0.78       0.1      99.9           46        0.03
   27  188.19        2.8        17.5  1429    46.9      0.74       0.1      99.9           46        0.02
   28  186.92        2.7        17.8  1400    46.0      0.75       0.1      99.9           46        0.01
   29  186.22        2.3        17.5  1368    45.2      0.74       0.0      99.9           46        0.01
   30  184.81        2.6        19.3  1395    45.1      0.75       0.0      99.9           46        0.01
   31  183.64        2.4        17.9  1422    44.1      0.71       0.0      99.9           48        0.01
   32  183.21        2.2        17.7  1400    43.4      0.71       0.0      99.9           49        0.01
=====  ======  =========  ==========  ====  ======  ========  ========  ========  ===========  ==========

30000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   16  64.43      180.9        18.8  11247    98.2      0.70      14.2      59.0         5283        2.81
   18  66.87      215.8        19.4  12263    98.3      0.70       9.5      59.2         5452        3.23
   20  67.22      256.4        19.0  13767    98.3      0.70       7.0      59.2         5481        3.81
   22  67.82      209.2        19.7  12470    98.4      0.70       5.1      59.2         5541        3.09
   24  67.86      182.8        19.6  12052    98.4      0.69       4.3      59.1         5575        2.69
   26  67.54      175.1        19.3  11956    98.2      0.69       3.9      59.0         5553        2.59
   28  67.74      169.6        19.3  11947    98.2      0.68       3.7      59.0         5582        2.50
   32  67.53      168.7        19.1  11954    98.1      0.69       3.4      58.9         5579        2.50
   36  67.57      168.7        19.1  12237    98.2      0.68       3.2      58.9         5589        2.50
   40  67.56      168.5        19.0  12158    98.3      0.68       3.0      59.0         5580        2.49
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

31000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   22  65.02      243.6        19.7  14165    98.6      0.70       6.3      57.8         5480        3.75
   24  62.45      298.4        18.6  18063    98.8      1.06       8.9      57.9         5285        4.78
   26  65.42      225.4        19.9  13527    98.3      0.69       4.6      57.9         5521        3.45
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

32000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   16  59.65      170.4        18.1  12457    98.7      0.68      16.2      56.1         5228        2.86
   18  62.45      183.3        18.6  13208    98.9      0.68      11.5      56.2         5462        2.94
   20  62.69      222.1        19.3  14785    98.7      0.69       8.9      56.4         5459        3.54
   22  60.07      269.0        18.3  17552    98.8      0.93      11.3      56.4         5228        4.48
   24  63.52      201.4        19.2  14493    98.8      0.68       5.8      56.3         5549        3.17
   26  61.69      248.7        19.0  16421    98.6      0.85       8.0      56.4         5343        4.03
   28  63.56      222.5        19.4  15612    98.8      0.73       5.4      56.4         5539        3.50
   32  63.70      215.6        19.4  15557    98.7      0.74       4.8      56.4         5549        3.38
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

35000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   20  48.23      320.4        15.3  28037    99.6      1.24      24.6      52.8         4484        6.64
   22  47.29      341.6        14.8  29505    99.6      1.34      24.7      52.9         4417        7.23
   24  48.29      320.1        15.2  29365    99.6      1.40      22.7      52.7         4519        6.63
   26  47.65      335.6        15.1  29443    99.5      1.53      23.5      52.9         4446        7.05
   28  48.98      323.6        15.5  28885    99.5      1.49      21.3      52.9         4580        6.61
   32  48.30      329.1        15.2  30155    99.5      1.69      21.9      52.8         4518        6.81
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

45000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   16   4.62      780.4         1.6  43349   100.0      3.31      77.7      43.7          500      168.83
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

97000 customers:

=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
Users  trtps  Read_MB/s  Write_MB/s   IOPS  Util_%  Await_ms  iowait_%  PG_hit_%  OS_req_MB/s  Read_MB/TR
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========
   16   1.98      389.8         0.8  32212   100.0      0.61      83.1      33.4          269      196.43
=====  =====  =========  ==========  =====  ======  ========  ========  ========  ===========  ==========

.. io-tables-end

**At 5000 customers storage is never a limit.**  The 60 GB database
fits in memory and the buffer cache hits 99.9 percent, so reads are
1 to 2 MB/s.  Writes are the write ahead log and the checkpoints,
rising with throughput from 5 to 18 MB/s at 350 to 1400 operations
per second, mostly the log writes at commit time, with the volume
busy half the time but each request waiting under a millisecond.
I/O wait peaks at 3.3 percent between 8 and 13 users and falls to
zero on the plateau, where the processors have no idle time in which
to wait.

Two runs differ from the rest.  At 21 users writes doubled to 32
MB/s for the hour, and at 23 users reads rose to 24 MB/s, writes to
50 MB/s and operations to 2050 per second.  The 23 user run is the
one with 1005 Trade Results given up on against about 100 in its
neighbors, and its statistics show why the storage traffic changed:
an autovacuum of ``holding``, 4.4 million rows, completed inside the
interval, and the three small tables that autovacuum otherwise
cleans every minute, ``broker``, ``trade_request`` and
``last_trade``, were cleaned 31 times instead of 58, because the
workers were busy with the large tables.  Less frequent cleaning of
the most heavily updated rows is a plausible cause of the extra
serialization retries, but that has not been established.

**At 30000 customers the page cache supplies most of the blocks.**
The database is three times memory and the buffer cache hits only
59 percent, so PostgreSQL asks the operating system for 5.3 to 5.6
GB/s of blocks.  The volume supplies 170 to 256 MB/s of that, so
the page cache serves about 96 percent of what the buffer cache
misses.  That costs 2.5 to 3.8 MB of disk reads per Trade Result,
at 11000 to 14000 operations per second with each waiting 0.7 ms.
The volume is busy 98 percent of the time, which for a stripe this
wide is 430 to 530 operations per second per
member, well within what such devices deliver, and the short wait
shows it is not saturated.  I/O wait falls as users are added, from
14 percent at 16 users to 4 percent at 28 at 30000 customers,
because more concurrent transactions overlap their reads with each
other's computation.  That is why the plateau at 30000 runs from 22
to 40 users instead of peaking: the added users add overlap rather
than throughput, while the processors are 83 to 94 percent busy in
user and system time, I/O wait not counted, with a quarter of that
in the kernel moving pages.  Both resources are near their limits at
this scale, and the processor is the one that limits throughput.

**At 97000 customers storage is the limit and nothing else is
significant.**  The 1170 GB database is nine times memory, the
buffer cache hits 33 percent, and the volume reads 390 MB/s at 32000
operations per second with utilization at 100 percent, while the
processors wait on I/O 83 percent of the time and compute 4 percent
of it.  Each Trade Result costs 196 MB of disk reads, sixty times
the figure at 30000.  The operating system's own requests come to
269 MB/s, less than the volume delivers, so the kernel's read ahead
fetches more than PostgreSQL asks for.  Whether the 32000 operations
per second is the stripe's limit or the members' is not established,
and the 0.6 ms wait shows that the devices themselves are not
queueing.

**Across the scales the disk read cost per Trade Result is the
quantity that drives the ratio's monotonic fall.**  It is 0.01 MB in
memory, 2.4 to 3.8 MB when the database is three times memory, and
196 MB at nine times.  Throughput falls 34 fold between 30000 and
97000 customers while the reads behind each transaction rise 60
fold, and the ceiling only doubles.

Against the documented limits
-----------------------------

The machine is an AWS r5b.4xlarge and the stripe's members are gp3
volumes.  Two sets of limits apply, the instance's and the volumes',
and the documented figures are these, read on 2026-09-10:

* the r5b.4xlarge is EBS-optimized by default with 10,000 Mbps of
  EBS bandwidth, 1,250 MB/s, and 43,333 IOPS, and for this size the
  baseline and the maximum are the same, so there is no burst
  capacity.  The family scales to 60 Gbps and 260,000 IOPS at
  24xlarge
* a gp3 volume delivers 3,000 IOPS and 125 MiB/s at baseline
  regardless of its size, can be provisioned up to 80,000 IOPS and
  2,000 MiB/s, does not burst, and is designed for single digit
  millisecond latency.  26 members at baseline are 78,000 IOPS and
  3,250 MiB/s in aggregate, well above the instance's limits, so the
  instance's limits are reached first unless the volumes are below
  baseline, which gp3 cannot be
* for solid state drive (SSD) volumes each random I/O of up to 256
  KiB counts as one operation, and physically sequential small I/Os
  may be merged into one.  PostgreSQL's reads here are random 8 KiB
  blocks, and the mean request the kernel issued was 12 to 17 KiB,
  so the operation rate ``sar`` reports for the volume is close to
  what EBS counts

Whether these volumes are provisioned above baseline could not be
read from the instance, because its permissions do not allow it to
describe volumes.  The comparison below assumes baseline.  If they
are provisioned higher, the per volume figures are further from
their limit still.

===================  =========  =========  ==========  ==========
Run                  IOPS       MB/s       Volume      Per member
                                           queue       IOPS
===================  =========  =========  ==========  ==========
5000, 16 users          1,328         19         1.2          51
30000, 24 users        12,052        204         8.3         464
97000, 16 users        32,212        391        19.5       1,239
Instance limit         43,333      1,250           -           -
Member baseline             -          -           -       3,000
===================  =========  =========  ==========  ==========

**No documented limit was reached at any scale.**  At 97000
customers, the point limited by storage, the volume ran at 74
percent of the instance's IOPS limit and 31 percent of its
bandwidth, and each member at 41 percent of its baseline IOPS and 12
percent of its baseline throughput.  At 30000 customers the figures
are 28 percent of the instance's IOPS, 16 percent of its bandwidth
and 15 percent of a member's baseline IOPS.  At 5000 the storage
traffic is the log, 3 percent of the instance's IOPS.

**What limited the 97000 point instead is latency multiplied by
concurrency.**  Every request waited 0.61 ms, inside gp3's single
digit milliseconds and no longer than at 30000 or 5000, which is
the behavior of an unthrottled volume: throttling would show as
rising wait with rising demand.  The volume had 19.5 requests
outstanding on average, which is the 16 users, the 16 market
exchange connections and the background writers each waiting on one
synchronous 8 KiB read at a time.  By Little's law 19.5 outstanding
requests at 0.61 ms each are 32,000 per second, which is what was
measured.  The rate is set by how many readers the workload keeps
waiting, not by the device.  Reaching the instance's 43,333 would
need about 26 outstanding requests, so more users would have raised
throughput at this scale, as the plan expected of a system limited
by I/O.  AWS's own
guideline for consistent latency is a queue of at most one request
per 1,000 provisioned IOPS per volume.  The members held 0.75
outstanding requests each against a guideline of 3 at baseline.

**Utilization does not measure how close to its limit a stripe
is.**  The volume reports 98 to 100 percent busy from 30000
customers up, because with 12,000 or more operations a second some
request is always outstanding on one of 26 members.  The members
themselves were busy 18 percent of the time at 30000 and 46 percent
at 97000.  The queue depth and the wait are the figures that show
how far from its limit a stripe is, and both show that it is far.

Utilization of the instance and the volumes
===========================================

The same measurements as percentages of the documented limits, so
that a run can be described by how much of each resource it used.
One row per reportable run, generated by ``utilization-table.sh``.
``CPU_%`` is the processors' busy share, user plus system plus nice,
averaged over the 16 logical processors, and ``iowait_%`` the share
they spent idle with I/O pending, which ``CPU_%`` does not include.
``inst_IOPS_%`` and ``inst_BW_%`` are the volume's operation rate
and bandwidth against the r5b.4xlarge's 43,333 IOPS and 10,000
Mbps, taken as 1192 MiB/s to match the binary units ``sar`` uses.
``member_IOPS_%`` and ``member_BW_%`` divide the volume's traffic
evenly over the 26 members and compare with a gp3 volume's baseline
of 3,000 IOPS and 125 MiB/s, which is the assumption the previous
section explains.  ``IO_%`` is the largest of the four, the storage
limit that would be reached first, and ``Limited_by`` names it.

.. util-tables-begin

5000 customers:

=====  ======  =====  ========  ===========  =========  =============  ===========  ====  ==============
Users   trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  ======  =====  ========  ===========  =========  =============  ===========  ====  ==============
    1   21.71     12       0.7          0.8        0.5            0.5          0.2     1  instance_IOPS
    2   42.90     19       1.3          1.1        0.6            0.6          0.2     1  instance_IOPS
    3   63.26     25       1.8          1.6        0.9            0.9          0.3     2  instance_IOPS
    4   82.98     32       2.3          1.9        1.0            1.1          0.4     2  instance_IOPS
    5  100.85     38       2.6          2.2        1.2            1.2          0.4     2  instance_IOPS
    6  115.66     45       2.9          2.3        1.2            1.3          0.4     2  instance_IOPS
    7  126.31     51       3.1          2.5        1.3            1.4          0.5     3  instance_IOPS
    8  136.07     58       3.2          2.7        1.4            1.5          0.5     3  instance_IOPS
    9  146.08     64       3.3          2.7        1.4            1.5          0.5     3  instance_IOPS
   10  156.79     71       3.3          2.9        1.4            1.6          0.5     3  instance_IOPS
   11  166.82     77       3.2          3.0        1.5            1.6          0.5     3  instance_IOPS
   12  176.68     83       3.1          3.1        1.6            1.7          0.6     3  instance_IOPS
   13  185.46     89       3.1          3.2        1.6            1.8          0.6     3  instance_IOPS
   14  190.74     94       2.2          3.1        1.6            1.7          0.6     3  instance_IOPS
   15  192.66     96       1.2          3.0        1.5            1.7          0.6     3  instance_IOPS
   16  193.59     98       0.8          3.1        1.6            1.7          0.6     3  instance_IOPS
   17  193.78     98       0.6          3.1        1.6            1.7          0.6     3  instance_IOPS
   18  193.63     98       0.4          3.0        1.6            1.7          0.6     3  instance_IOPS
   19  190.16     99       0.3          3.0        1.5            1.7          0.6     3  instance_IOPS
   20  192.04     99       0.3          3.0        1.6            1.7          0.6     3  instance_IOPS
   21  192.74     99       0.3          3.3        2.8            1.8          1.0     3  instance_IOPS
   22  192.10     99       0.2          3.2        1.7            1.8          0.6     3  instance_IOPS
   23  188.93     99       0.2          4.7        6.2            2.6          2.3     6  instance_MiB/s
   24  190.87     99       0.2          3.9        2.0            2.2          0.7     4  instance_IOPS
   25  190.10    100       0.1          3.3        1.7            1.8          0.6     3  instance_IOPS
   26  188.79    100       0.1          3.5        2.1            1.9          0.8     3  instance_IOPS
   27  188.19    100       0.1          3.3        1.7            1.8          0.6     3  instance_IOPS
   28  186.92    100       0.1          3.2        1.7            1.8          0.6     3  instance_IOPS
   29  186.22    100       0.0          3.2        1.7            1.8          0.6     3  instance_IOPS
   30  184.81    100       0.0          3.2        1.8            1.8          0.7     3  instance_IOPS
   31  183.64    100       0.0          3.3        1.7            1.8          0.6     3  instance_IOPS
   32  183.21    100       0.0          3.2        1.7            1.8          0.6     3  instance_IOPS
=====  ======  =====  ========  ===========  =========  =============  ===========  ====  ==============

30000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   16  64.43     83      14.2         26.0       16.8           14.4          6.1    26  instance_IOPS
   18  66.87     88       9.5         28.3       19.7           15.7          7.2    28  instance_IOPS
   20  67.22     90       7.0         31.8       23.1           17.6          8.5    32  instance_IOPS
   22  67.82     91       5.1         28.8       19.2           16.0          7.0    29  instance_IOPS
   24  67.86     92       4.3         27.8       17.0           15.5          6.2    28  instance_IOPS
   26  67.54     92       3.9         27.6       16.3           15.3          6.0    28  instance_IOPS
   28  67.74     92       3.7         27.6       15.8           15.3          5.8    28  instance_IOPS
   32  67.53     93       3.4         27.6       15.8           15.3          5.8    28  instance_IOPS
   36  67.57     93       3.2         28.2       15.8           15.7          5.8    28  instance_IOPS
   40  67.56     94       3.0         28.1       15.7           15.6          5.8    28  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

31000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   22  65.02     90       6.3         32.7       22.1           18.2          8.1    33  instance_IOPS
   24  62.45     87       8.9         41.7       26.6           23.2          9.8    42  instance_IOPS
   26  65.42     92       4.6         31.2       20.6           17.3          7.5    31  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

32000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   16  59.65     80      16.2         28.7       15.8           16.0          5.8    29  instance_IOPS
   18  62.45     86      11.5         30.5       16.9           16.9          6.2    30  instance_IOPS
   20  62.69     88       8.9         34.1       20.2           19.0          7.4    34  instance_IOPS
   22  60.07     85      11.3         40.5       24.1           22.5          8.8    41  instance_IOPS
   24  63.52     91       5.8         33.4       18.5           18.6          6.8    33  instance_IOPS
   26  61.69     88       8.0         37.9       22.5           21.1          8.2    38  instance_IOPS
   28  63.56     91       5.4         36.0       20.3           20.0          7.4    36  instance_IOPS
   32  63.70     92       4.8         35.9       19.7           19.9          7.2    36  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

35000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   20  48.23     73      24.6         64.7       28.2           35.9         10.3    65  instance_IOPS
   22  47.29     73      24.7         68.1       29.9           37.8         11.0    68  instance_IOPS
   24  48.29     75      22.7         67.8       28.1           37.6         10.3    68  instance_IOPS
   26  47.65     74      23.5         67.9       29.4           37.7         10.8    68  instance_IOPS
   28  48.98     76      21.3         66.7       28.5           37.0         10.4    67  instance_IOPS
   32  48.30     76      21.9         69.6       28.9           38.7         10.6    70  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

45000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   16   4.62     14      77.7        100.0       65.6           55.6         24.1   100  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

97000 customers:

=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
Users  trtps  CPU_%  iowait_%  inst_IOPS_%  inst_BW_%  member_IOPS_%  member_BW_%  IO_%  Limited_by
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============
   16   1.98      8      83.1         74.3       32.8           41.3         12.0    74  instance_IOPS
=====  =====  =====  ========  ===========  =========  =============  ===========  ====  =============

.. util-tables-end

Stated in terms of resources, a run at 30000 customers and 24 users,
the answer, used 92 percent of the processing resources, in user and
system time, waited on I/O for a further 4 percent, and used 28
percent of the I/O resources, limited on the storage side by the
instance's IOPS before anything else.  The same statement for the
other scales, on the same definitions:

=====================  ======  ==========  ======  ==============
Run                     CPU %  I/O wait %    IO %  I/O limit
=====================  ======  ==========  ======  ==============
5000, 16 users             98         0.8       3  instance IOPS
30000, 24 users            92         4.3      28  instance IOPS
97000, 16 users             8        83.1      74  instance IOPS
=====================  ======  ==========  ======  ==============

Three qualifications apply when reading them.  The storage limit
reached first is the instance's IOPS at every scale, because the 26
members' baselines add up to 78,000 IOPS and 3,250 MiB/s, above
anything the instance can carry, and because 8 to 16 KiB requests
reach the operation limit long before the bandwidth limit.  The
bandwidth columns never pass 33 percent.  The processing figure
counts all 16 logical processors and excludes I/O wait, so 92
percent busy is the eight cores saturated with their second hardware
threads adding what they can, as phase 0 established.  The two
figures do not add up to 100 percent: the processors' time waiting
on I/O is a third share, 4 percent at 30000 customers and 24 users,
83 percent at 97000, and it is where the processing capacity of a
run limited by storage is spent.

What the profiles show across the regimes
=========================================

The 20 second profile in the middle of every run gives the
processor's view of each regime: which PostgreSQL backend routines
and which kernel routines it was executing.  ``profile-table.sh``
tabulates a set of runs side by side, ranking symbols by their
largest share in any of the runs.  Percentages are of all samples in
the profile, the idle loop included, so they are shares of the
machine rather than of a process.  The profiler samples time on the
processor, so these are the most sampled routines, not the most
called, and a routine that blocks does not appear.

.. profile-tables-begin

**Across the regimes at 5000 customers**, 1, 4, 8, 16, 24 and 32
users: the end of the first linear regime, the second, the
plateau, and the decline.

Share of samples by component, percent:

=========  ======  ======  ======  =======  =======  =======
Component  5000/1  5000/4  5000/8  5000/16  5000/24  5000/32
=========  ======  ======  ======  =======  =======  =======
idle         87.7    68.1    42.5      2.7      0.6      0.2
kernel        2.5     4.1     5.6      7.2      5.9      5.6
pg            5.5    22.4    46.0     83.0     87.3     88.4
mee           3.2     3.0     2.6      2.1      1.4      1.0
bh            0.1     0.6     1.1      2.1      2.1      1.9
driver        0.0     0.0     0.0      0.1      0.1      0.1
other         0.0     0.0     0.0      0.1      0.1      0.1
=========  ======  ======  ======  =======  =======  =======

PostgreSQL backend symbols, percent of all samples:

============================  ======  ======  ======  =======  =======  =======
Symbol                        5000/1  5000/4  5000/8  5000/16  5000/24  5000/32
============================  ======  ======  ======  =======  =======  =======
hash_search_with_hash_value      1.0     3.0     5.8     10.2     10.5     11.4
heap_page_prune_opt              0.6     2.2     4.3      7.3      7.8      8.0
PinBuffer                        0.4     1.9     3.3      5.5      6.2      6.2
heap_hot_search_buffer           0.3     1.4     3.1      5.7      6.2      6.2
ExecInterpExpr                   0.3     1.2     2.6      4.5      5.1      5.0
LWLockAttemptLock                0.1     1.0     2.0      3.1      3.5      3.6
fill_val                         0.2     1.0     1.9      3.3      3.5      3.4
tts_buffer_heap_getsomeattrs     0.2     0.8     1.5      2.8      3.0      2.8
ExecHashJoin                     0.1     0.3     0.7      1.5      1.6      1.4
tts_minimal_getsomeattrs         0.1     0.3     0.5      1.2      1.1      1.3
============================  ======  ======  ======  =======  =======  =======

Kernel symbols, from any process, percent of all samples:

===========================  ======  ======  ======  =======  =======  =======
Symbol                       5000/1  5000/4  5000/8  5000/16  5000/24  5000/32
===========================  ======  ======  ======  =======  =======  =======
_raw_spin_unlock_irqrestore     1.9     2.5     3.2      3.3      2.4      1.9
finish_task_switch.isra.0       0.1     0.1     0.2      0.7      0.7      0.6
do_syscall_64                   0.2     0.4     0.4      0.4      0.3      0.3
rep_movs_alternative            0.0     0.1     0.2      0.2      0.1      0.1
clear_page_erms                 0.0     0.0     0.1      0.1      0.1      0.1
irqentry_exit_to_user_mode      0.0     0.0     0.0      0.1      0.1      0.1
do_user_addr_fault              0.0     0.1     0.1      0.1      0.1      0.1
fdget                           0.0     0.0     0.1      0.1      0.1      0.1
handle_softirqs                 0.0     0.0     0.0      0.1      0.1      0.1
get_mem_cgroup_from_mm          0.0     0.0     0.0      0.0      0.1      0.0
===========================  ======  ======  ======  =======  =======  =======

**Across the scales**, at the reported optimum of each, with
40 users at 30000 for the upper end of its plateau.

Share of samples by component, percent:

=========  =======  ========  ========  ========
Component  5000/16  30000/24  30000/40  97000/16
=========  =======  ========  ========  ========
idle           2.7       8.9       6.6      91.4
kernel         7.2      25.2      26.8       4.2
pg            83.0      60.7      61.7       2.3
mee            2.1       2.2       2.1       1.5
bh             2.1       0.7       0.5       0.0
driver         0.1       0.0       0.0       0.0
other          0.1       0.0       0.1       0.1
=========  =======  ========  ========  ========

PostgreSQL backend symbols, percent of all samples:

============================  =======  ========  ========  ========
Symbol                        5000/16  30000/24  30000/40  97000/16
============================  =======  ========  ========  ========
hash_search_with_hash_value      10.2       8.4       8.6       0.3
heap_page_prune_opt               7.3       1.7       1.8       0.0
pg_checksum_page                  0.0       6.5       6.2       0.2
heap_hot_search_buffer            5.7       1.1       1.2       0.0
PinBuffer                         5.5       1.3       1.4       0.0
ExecInterpExpr                    4.5       2.5       2.3       0.1
fill_val                          3.3       1.8       1.8       0.1
LWLockAttemptLock                 3.1       1.8       1.7       0.1
tts_buffer_heap_getsomeattrs      2.8       2.2       2.2       0.1
0x000000000008f687                0.1       2.3       2.3       0.1
============================  =======  ========  ========  ========

Kernel symbols, from any process, percent of all samples:

===========================  =======  ========  ========  ========
Symbol                       5000/16  30000/24  30000/40  97000/16
===========================  =======  ========  ========  ========
rep_movs_alternative             0.2      10.0      10.3       0.5
_raw_spin_unlock_irqrestore      3.3       3.5       3.3       1.1
xas_load                         0.0       2.0       2.1       0.2
filemap_get_read_batch           0.0       1.3       1.4       0.1
do_syscall_64                    0.4       1.1       1.1       0.1
finish_task_switch.isra.0        0.7       0.7       0.9       0.2
filemap_read                     0.0       0.7       0.8       0.0
clear_page_erms                  0.1       0.3       0.4       0.2
fdget                            0.1       0.3       0.4       0.0
_copy_to_iter                    0.0       0.3       0.3       0.0
===========================  =======  ========  ========  ========

.. profile-tables-end

**At 5000 customers the backends do the same work at every user
count, and only the amount changes.**  From 1 user to 32 the
postgres share of samples rises from 5 to 88 percent, and every one
of the ten leading backend routines rises in the same proportion:
buffer table lookup, HOT chain pruning and search, buffer pinning,
expression evaluation and tuple deforming keep their relative sizes
to within a few tenths of a percent across the whole sweep.  The
change of slope between 4 and 7 users and the plateau from 16 are
therefore not changes in what the workload does.  A contention
problem, or a lock convoy, would show as one routine growing faster
than the rest.  They are the processor topology: the same
instruction mix first fills the cores, then their second threads,
then nothing.  The one routine whose share changes is lock
acquisition, ``LWLockAttemptLock``, from 3.1 percent at 16 users to
3.6 at 32, alongside pruning from 7.3 to 8.0, which is the mild
contention behind the 5 percent decline past 22 users.  The kernel's
share peaks at 7 percent at 16 users and is mostly
``_raw_spin_unlock_irqrestore``, the wake up path of the sockets
between the harness and the backends, which grows with the rate of
requests until the plateau and then shrinks with it.

**Once the database exceeds memory, a quarter of the machine's time
is spent moving pages.**  At 30000 customers the kernel's share of
samples rises from 7 to 25 percent, and the largest item in
it is ``rep_movs_alternative`` at 10 percent, the copy of page cache
pages into ``shared_buffers`` on ``read``, followed by the page
cache lookup, ``xas_load``, ``filemap_get_read_batch`` and
``filemap_read``, at 4 percent.  The backends' own routines fall
correspondingly: pruning from 7.3 to 1.8 percent, HOT search from
5.7 to 1.2, pinning from 5.5 to 1.4, while buffer table lookup holds
at 8 to 9 percent because every access still goes through it.  The
work per transaction has not changed.  The backends spend a third of
their time asking the kernel for pages instead of processing them.
The plateau at 30000 has the same profile at 24 and 40 users, to
within a few tenths of a percent, as its flat throughput implies.

**Checksums are a tenth of the backends' time once the database no
longer fits.**  ``pg_checksum_page`` does not appear at 5000
customers and takes 6.2 to 6.5 percent of all samples at 30000, a
tenth of the backends' own share.  The cluster was initialized with
data checksums, and PostgreSQL verifies a page's checksum each time
it reads the page from the operating system.  At 5000 customers
nothing is read from the operating system, so nothing is verified.
At 30000, with 5.5 GB/s of pages arriving from the page cache, every
one of them is.  Together with the kernel's copying and lookup,
about a fifth of the machine at this scale is spent moving pages
into ``shared_buffers`` and checking them, which is the symbol level
view of the quarter of processor time the kernel accounts for in the
storage section.

**At 97000 customers the processor is not the limit.**  91 percent
of samples are the idle loop, the backends have 2 percent and the
kernel 4, and what little runs is the same mix as at 30000.  The
profile confirms the storage section's reading: the machine waits.

What the database statistics show about caching and indexes
============================================================

The statistics collector sampled ``pg_stat_all_tables``,
``pg_statio_all_tables``, ``pg_stat_all_indexes`` and
``pg_statio_all_indexes`` once a minute during every run, into
``dbstat/`` under the run's database directory.  ``dbstat-table.sh``
takes the difference between the first and the last sample of a
run, which spans the measurement interval and the one minute warmup
before it, for one run per customer count, the reported optimum of
each.  Two limits apply to what these statistics can say.  They
count hits and misses in ``shared_buffers`` only: a miss is a block
PostgreSQL asked the operating system for, and whether the page
cache or the disk supplied it is not recorded by table.  The overall
page cache share comes from the storage section, where at 30000
customers the page cache served about 96 percent of the misses.  A
per table view of the page cache would need a tool such as
``fincore`` run over the table files at the end of each run, which
the collector does not do.

**One table is the cache.**  The ``trade`` table, 66.56 GB at 32000
customers, accounts for 81 percent of all block requests at that
scale and 97 percent of all blocks read from the operating system,
and for 86 percent of the requests at 5000 customers, where it is
served entirely from ``shared_buffers`` at 5 million block requests
per second.  Every other table together is less than a fifth of the
requests and 3 percent of the reads.  What is cached, at every
scale, is therefore decided by how ``trade`` is read.

**What stays cached beyond memory.**  At 30000, 32000 and 35000
customers the ``trade`` heap hits ``shared_buffers`` 43 to 50
percent of the time and its index blocks 78 to 80 percent.  Its
misses arrive at 680 thousand blocks per second at 32000 customers,
against a pool of 4.2 million buffers, so the pool turns over about
every six seconds, and a page survives in it only if it is used
again within a few seconds.  The tables that are used thousands of
times per second, ``security``, ``last_trade``, ``company``,
``customer_taxrate``, ``broker``, ``trade_request`` and the small
reference tables, stay at 100 percent at every scale, because every
one of their pages is touched faster than the pool turns over.
Tables used tens of times per second are evicted whatever their
size: ``daily_market``, 1.88 GB, hits 22 percent, ``financial``, 40
MB, hits 9 percent, and ``account_permission``, 16 MB, hits 1
percent, and the page cache serves them instead.  At 97000
customers ``trade`` hits 16 percent, and even ``customer`` and
``watch_list`` fall to 56 and 39 percent.  At 5000 customers, where
the database is 60 GB against 32 GB of ``shared_buffers``,
everything hits 94 percent or more except the three history tables
that are written once and read rarely, ``trade_history``,
``settlement`` and ``cash_transaction``, at 74 to 84 percent, and
the page cache holds the rest, which is the 99.9 percent overall
hit rate of the storage section.

**The system catalogs cost nothing.**  Together the ``pg_catalog``
tables receive 370 to 450 block requests per second, 0.01 to 0.03
percent of all requests, at a hit ratio of 98 to 100 percent.  At
97000 customers their share rises to 0.7 percent only because the
total falls thirty fold.

**Why trade is read so heavily.**  ``trade`` is never scanned
sequentially.  Its index ``i_t_ca_id`` is scanned 185 times per
second at 32000 customers, and each scan reads 4212 rows, every
trade of one customer account, and ``i_t_s_symb`` 19 times per
second at 25321 rows per scan, every trade of one security.  The
queries behind them want a few of those rows.  Trade-Status frame
1 and Customer-Position frame 2 return the newest 50 and 10 trades
of an account, ordered by ``t_dts``, and Trade-Lookup frames 2 and
3 and Trade-Update frames 2 and 3 return at most 20 trades of an
account or a security inside a date range.  Because the indexes
hold only ``t_ca_id`` or ``t_s_symb``, the executor fetches every
trade of the account or the security from the heap and then sorts
or filters by ``t_dts``, and the planner shows it: the plan of each
query is an index scan estimated at 4201 rows, then a sort, then
the limit.  Those rows lie on as many distinct heap pages, since an
account's trades are spread over the whole table.  That is the 1.3
million heap block accesses per second on ``trade`` at 32000
customers, the 5.3 GB/s the storage section attributes to requests
to the operating system, and the 196 MB of disk reads per Trade
Result at 97000 customers.

Two indexes are missing for this workload, ``(t_ca_id, t_dts)`` and
``(t_s_symb, t_dts)``.  With them each of those queries would read
the ten to fifty rows it returns, about a hundredth of what it reads
now, and the block traffic of ``trade``, four fifths of all block
requests at every scale, would fall by about the same factor. That
would change the shape of this whole exercise.  The collapse of
throughput with database size is this traffic, and at 5000 customers
the same scans are the largest part of the buffer lookups that head
the processor profile.  The specification leaves the choice of
indexes to the sponsor, and nothing is changed during the exercise,
so this is a finding for a later exercise rather than a change made
here.

**Indexes that are not used.**  Of the 45 indexes on the TPC-E
tables, 43 are scanned in every one of the 66 reportable runs,
``pk_sector`` in 25 of them, where the planner chose it over a
sequential scan of the 12 row ``sector`` table, and ``pk_charge``
in none: ``charge`` has 15 rows and is read by a sequential scan,
and its index exists only to enforce the key.  Two more are scanned
only by maintenance.  ``i_t_st_id``, 3.65 GB at 32000 customers, is
scanned exactly once per run, and ``i_dm_s_symb``, 0.19 GB, five
times per run, which is the Data-Maintenance transaction's update of
``daily_market`` every twelve minutes.  ``i_t_st_id`` has a cost
beyond its size.  Every Trade-Result updates ``t_st_id``, an indexed
column, so that update cannot be a heap only tuple (HOT) update and
must add an entry to all four indexes of ``trade``.  Only 36 percent
of the updates of ``trade`` are HOT at 32000 customers, against 89
to 100 percent for ``last_trade``, ``broker``, ``customer_account``,
``holding_summary`` and ``holding``.  ``settlement`` and
``cash_transaction`` are at 50 and 42 percent at 32000 customers
and at 99 and 95 percent at 5000, a difference the statistics do
not explain.  Dropping ``i_t_st_id`` would let the Trade-Result
updates be HOT wherever the page has room.

**Sequential scans.**  The tables scanned sequentially are the
small reference tables, ``trade_type``, ``status_type``,
``exchange``, ``charge``, ``sector``, ``industry``, ``taxrate`` and
``broker``, with 3 to 320 rows, where a sequential scan is the
right plan, and two others.  ``trade_request``, about 3600 rows of
pending limit orders, is scanned 31 times per second at 32000
customers by Broker-Volume, whose plan hashes the whole table.
``security``, 21920 rows at 32000 customers, is scanned 119 times
per second there and 384 times per second at 5000 customers: the
plan of Trade-Status frame 1 joins ``security`` to the account's
trades with a hash join, building a hash of the whole table for
every call, instead of fifty lookups through ``pk_security``.  That
is 2.6 million rows scanned per second at 32000 customers and 1.3
million at 5000, all from ``shared_buffers``, which is processor
time rather than storage.  No large table is scanned sequentially,
so the missing indexes are not visible as sequential scans.  They
are visible only as the rows read per index scan.

Recommendations on the indexes
------------------------------

The specification permits every change below.  Clause 2.3.11 makes
an index a User-Defined Object, and clause 2.3.11.1 places no
restriction on those beyond the frame rules of clause 3.2 and the
ACID rules of clause 7.  Clauses 2.2.3.1 to 2.2.3.3 and 2.4.3
require the primary keys, foreign keys and constraints of clause
2.2 to be maintained during the test run, so every primary key
index stays, ``pk_charge`` included, though the order of the
columns inside a primary key index is an implementation choice.
Clause 2.3.8, comment 2, requires the initial access to a row in a
transaction to use the columns named in the transaction profile,
which the composite indexes below do.  Clause 9.3.2.1 requires the
physical organization of tables and indexes, fill factors included,
to be disclosed, and clause 9.3.9 lists the index creation scripts
among the supporting files, so the broker fill factor of 10 used
here and any of these changes would appear in a compliant report.
Clause 2.3.9 requires room for 5 percent more rows, indexes
included.

None of the changes has been measured.  In order of the strength of the
recommendation:

1. **Replace** ``i_t_ca_id`` **with an index on**
   ``(t_ca_id, t_dts)``.  Strong.  The current index reads 4212
   rows per scan, 185 scans per second at 32000 customers, because
   Trade-Status frame 1 and Customer-Position frame 2 sort every
   trade of an account to return the newest 50 or 10, and
   Trade-Lookup and Trade-Update frame 2 filter them by date.  That
   is about 60 percent of the heap traffic on ``trade``, which is
   81 percent of all block requests.  With the composite index
   those queries read the rows they return.  It should also let the
   planner stop Trade-Status frame 1 after 50 rows and join
   ``security`` by its primary key instead of hashing the whole
   table on every call.  The evidence is the query plans and the
   statistics, not a measured run.
2. **Replace** ``i_t_s_symb`` **with an index on**
   ``(t_s_symb, t_dts)``.  Strong, for the same reason: 25321 rows
   per scan at 19 scans per second is the other 40 percent of the
   heap traffic on ``trade``, from Trade-Lookup and Trade-Update
   frame 3.
3. **Reorder** ``pk_daily_market`` **to** ``(dm_s_symb, dm_date)``
   **and drop** ``i_dm_s_symb``.  Moderate.  Security-Detail frame
   1 asks for one symbol's rows from a start date, and the plan
   walks the primary key index from that date across every symbol
   until it has found 20 rows of the one it wants.  With the symbol
   first that is a range of 20 entries, Market-Watch's lookups by
   symbol and date are unaffected, and the 190 MB index scanned
   five times an hour becomes redundant.  The gain is small in
   absolute terms, since ``daily_market`` is under 3 percent of
   block requests.
4. **Drop** ``i_t_st_id``.  Moderate.  It is 3.65 GB, maintained by
   every Trade-Order insert and Trade-Result update, and scanned
   once per run by a script outside the measurement interval, not
   by any stored function.  Trade-Result frame 5 updates ``t_dts``
   as well as ``t_st_id``, so once ``t_dts`` is indexed by the
   first two changes that update stays a non-HOT update either way.
   The gain is one index less to maintain and 3.65 GB less competing
   for the cache, not HOT updates.
5. **Reorder** ``pk_customer_taxrate`` **to** ``(cx_c_id, cx_tx_id)``.
   Weak.  Trade-Result frame 3 selects by customer, and with the tax
   rate identifier first PostgreSQL 18 answers it with a skip scan
   over about 320 values.  The table is tiny and fully cached, so
   this is processor time only.
6. **Leave every other index as it is.**  Each is used in every run
   with a few rows per scan, and the required primary keys cannot
   go.

The first two changes would change the shape of the sizing
exercise itself, since the collapse of throughput with database
size is this traffic, so a sizing exercise with the new indexes must
start again from its baseline.

The tables follow.  Rates are per second over the run.

.. dbstat-tables-begin

Buffer cache hit ratio of heap blocks in shared_buffers, percent, by
table, over each run.  GB is the table's heap size at 32000
customers.  Tables are ordered by their block requests in the third
run.

==================  =====  =======  ========  ========  ========  ========
Table                  GB  5000/16  30000/24  32000/18  35000/28  97000/16
==================  =====  =======  ========  ========  ========  ========
trade               66.56    100.0      50.2      46.9      43.1      15.8
security             0.00    100.0     100.0     100.0     100.0     100.0
daily_market         1.88    100.0      23.2      21.7      19.7       6.9
last_trade           0.00    100.0     100.0     100.0     100.0     100.0
company              0.00    100.0     100.0     100.0     100.0      99.5
customer_taxrate     0.00    100.0      97.8      96.6      97.7      99.4
trade_history       64.82     81.0      25.5      24.7      24.9      26.3
settlement          35.22     83.9      39.6      38.4      40.7      42.7
cash_transaction    56.14     74.3      40.1      39.2      41.1      42.7
news_xref            0.00    100.0     100.0     100.0     100.0     100.0
holding_summary      0.09    100.0      87.8      87.0      85.9      85.7
customer_account     0.02    100.0      87.7      86.3      84.9      79.2
holding              2.19    100.0      94.9      93.8      95.7      97.4
trade_request        0.00    100.0     100.0     100.0     100.0     100.0
broker               0.00    100.0     100.0     100.0     100.0     100.0
customer             0.01    100.0      96.3      94.7      92.1      55.9
status_type          0.00    100.0     100.0     100.0     100.0     100.0
holding_history     36.23     94.4      94.5      94.0      94.5      92.6
trade_type           0.00    100.0     100.0     100.0     100.0     100.0
industry             0.00    100.0     100.0     100.0     100.0     100.0
news_item            0.01    100.0      62.3      61.0      59.6      50.4
zip_code             0.00    100.0      99.7      99.7      99.6      99.2
address              0.00    100.0      99.7      99.4      99.4      76.8
financial            0.04    100.0      10.1       9.4       8.5       6.6
company_competitor   0.00    100.0     100.0     100.0     100.0     100.0
watch_item           0.14    100.0      99.7      99.6      99.7      99.8
commission_rate      0.00    100.0     100.0     100.0     100.0     100.0
exchange             0.00    100.0     100.0     100.0     100.0     100.0
watch_list           0.00    100.0      91.1      87.8      83.0      39.0
taxrate              0.00    100.0     100.0     100.0     100.0      99.9
charge               0.00    100.0     100.0     100.0     100.0     100.0
sector               0.00    100.0     100.0     100.0     100.0     100.0
account_permission   0.02    100.0       1.5       1.4       1.2       4.4
==================  =====  =======  ========  ========  ========  ========

Buffer cache hit ratio of index blocks in shared_buffers, percent, by
table, the same runs and order.

==================  =======  ========  ========  ========  ========
Table               5000/16  30000/24  32000/18  35000/28  97000/16
==================  =======  ========  ========  ========  ========
trade                  99.6      79.6      78.9      78.4      73.8
security              100.0     100.0     100.0     100.0     100.0
daily_market          100.0      93.5      93.2      92.7      87.0
last_trade            100.0     100.0     100.0     100.0     100.0
company               100.0     100.0     100.0      99.9      98.5
customer_taxrate      100.0     100.0     100.0     100.0      99.9
trade_history          95.1      69.1      68.7      68.5      72.4
settlement             99.3      75.6      75.1      74.9      70.7
cash_transaction       99.2      76.0      75.6      75.3      71.2
news_xref             100.0     100.0     100.0     100.0     100.0
holding_summary       100.0      93.1      92.8      92.7      91.6
customer_account      100.0      99.4      99.2      98.8      92.1
holding                99.0      80.0      78.3      82.0      79.6
trade_request         100.0      99.0      99.1      99.3     100.0
broker                100.0     100.0     100.0     100.0     100.0
customer              100.0      99.2      99.0      98.8      96.4
status_type            99.5      99.4      99.2      99.1      99.0
holding_history        95.1      82.4      81.3      81.4      76.0
trade_type             99.8      99.8      99.7      99.6      99.8
industry              100.0     100.0     100.0     100.0     100.0
news_item             100.0     100.0     100.0     100.0      98.1
zip_code              100.0     100.0     100.0     100.0     100.0
address               100.0     100.0     100.0     100.0      99.7
financial             100.0      75.6      74.9      74.0      68.4
company_competitor    100.0      95.2      95.6      94.0      78.4
watch_item            100.0      60.4      60.2      60.1      63.3
commission_rate       100.0     100.0     100.0     100.0     100.0
exchange               99.5      99.5      99.3      99.6      99.5
watch_list            100.0     100.0      99.9      99.8      81.6
taxrate               100.0      96.1      94.9      96.5     100.0
charge                 93.8      95.8      94.4      96.4      93.8
sector                 93.8     100.0     100.0      96.4      99.8
account_permission    100.0      67.6      67.5      67.1      62.6
==================  =======  ========  ========  ========  ========

Share of all block requests and of the blocks read from the
operating system, percent, by table, in the third and the last run;
the twelve tables with the largest share of the reads in the third
run, and the system catalogs together.

================  ============  =============  ============  =============
Table             Req_32000/18  Read_32000/18  Req_97000/16  Read_97000/16
================  ============  =============  ============  =============
trade                    80.85          97.31         77.79          97.88
daily_market              2.73           1.22          2.65           1.09
trade_history             0.58           0.58          0.63           0.35
settlement                0.47           0.37          0.47           0.26
cash_transaction          0.45           0.34          0.45           0.24
holding_summary           0.25           0.05          0.22           0.03
holding                   0.12           0.03          0.16           0.02
financial                 0.02           0.03          0.02           0.02
holding_history           0.06           0.02          0.05           0.01
customer_account          0.16           0.02          0.17           0.03
watch_item                0.02           0.01          0.02           0.01
news_item                 0.03           0.01          0.03           0.01
(catalogs)                0.03           0.00          0.72           0.00
================  ============  =============  ============  =============

Sequential scans per second by table, with the rows each scan read
in the third run; tables scanned sequentially in any of the runs.

=============  =========  =======  ========  ========  ========  ========
Table          Rows/scan  5000/16  30000/24  32000/18  35000/28  97000/16
=============  =========  =======  ========  ========  ========  ========
trade_type             3  2338.94    818.00    747.61    587.46     23.00
status_type            3  1478.59    511.10    466.85    367.08     14.66
exchange               3   643.31    225.75    207.52    162.92      6.54
security           21920   383.65    129.97    119.48     93.80      3.77
charge                15   196.90     69.09     63.51     49.87      2.02
industry             102   112.32     38.76     35.61     28.36      0.20
taxrate              320     0.00     35.58     31.42     25.05      0.00
trade_request       3595     2.90     33.52     30.81     24.19      0.97
broker               320    95.51     33.11     30.81     24.19      0.19
sector                12    95.53     33.12     30.41     24.19      2.77
company             2500    94.33      0.00      0.00      0.00      0.00
=============  =========  =======  ========  ========  ========  ========

Updates per second and the share of them done as heap only tuple
(HOT) updates, percent, by table, in the first and the third run;
tables with more than one update per second in the third run.

================  =============  ===========  ==============  ============
Table             Upd/s_5000/16  HOT_5000/16  Upd/s_32000/18  HOT_32000/18
================  =============  ===========  ==============  ============
trade                     637.1         47.9           198.6          35.9
last_trade                384.0        100.0           123.6         100.0
settlement                255.5         99.2            82.0          49.6
cash_transaction          244.0         94.8            78.3          41.9
holding_summary           239.0         98.5            70.6          97.9
broker                    206.8        100.0            63.5         100.0
customer_account          183.6         99.7            57.5          99.8
holding                    88.5         94.2            25.8          89.4
================  =============  ===========  ==============  ============

System catalog tables, all of pg_catalog together: block requests
per second, their share of all block requests, percent, and their
hit ratio in shared_buffers, percent.

========  ==========  =====  =====
Run       Requests/s  Share    Hit
========  ==========  =====  =====
5000/16          450  0.009  100.0
30000/24         431  0.025   98.1
32000/18         401  0.025   98.0
35000/28         424  0.034   98.3
97000/16         371  0.722  100.0
========  ==========  =====  =====

Index scans per second by index, and the number of the 66 reportable
runs in which the index was scanned at all (Used).  Indexes are
ordered by their scans in the third run.

=====================  =======  ========  ========  ========  ========  ====
Index                  5000/16  30000/24  32000/18  35000/28  97000/16  Used
=====================  =======  ========  ========  ========  ========  ====
pk_security            24581.3   21498.5   18232.2   12016.9     251.8    66
pk_last_trade          37808.5   13406.8   12356.5    9702.6     389.3    66
pk_company              1944.8   13410.2   10768.9    6150.5      17.0    66
pk_customer_taxrate     1004.7   11384.7   10053.2    8017.4     102.9    66
pk_daily_market        26943.3    9614.2    8869.0    6969.7     279.7    66
pk_trade                5335.2    1857.3    1680.1    1326.3      51.0    66
pk_trade_history        4862.1    1705.2    1567.3    1232.5      49.2    66
pk_settlement           4098.9    1439.0    1320.2    1041.2      41.4    66
pk_cash_transaction     3863.2    1354.1    1244.2     979.2      39.1    66
pk_holding_summary      2330.5     811.4     735.0     580.9      22.7    66
pk_customer_account     1453.5     505.5     457.9     361.7      14.2    66
pk_customer             1061.3     370.6     336.0     265.5      10.4    66
pk_industry             1203.7     352.5     318.2     223.4      12.8    66
i_security             20182.0     331.5     305.3     246.0      10.2    66
pk_broker                862.1     371.9     272.9     215.2      94.6    66
i_t_ca_id                572.4     200.7     184.6     144.8       5.8    66
pk_news_item             546.0     191.7     176.2     138.4       5.7    66
pk_zip_code              545.9     191.7     176.2     138.4       5.7    66
pk_address               545.9     191.7     176.2     138.4       5.6    66
pk_commission_rate       436.8     151.2     134.6     107.4       4.0    66
i_tr_s_symb            26871.1     135.5     124.4      98.1       4.7    66
pk_news_xref             273.0      95.9      88.2      69.3       2.9    66
pk_financial             272.9      95.8      88.0      69.1       2.8    66
pk_company_competitor    272.9      95.8      88.0      69.1       2.8    66
i_ca_c_id                254.2      89.4      81.8      64.3       2.6    66
i_holding                224.2      78.6      69.8      56.0       2.0    66
pk_watch_item            210.6      73.9      68.0      53.5       2.2    66
i_wl_c_id                210.6      73.8      67.9      53.4       2.1    66
pk_holding               213.1      75.3      64.4      52.9       1.6    66
i_c_tax_id               126.8      44.5      41.0      32.1       1.3    66
i_co_name                 78.5      27.6      25.4      20.0       0.8    66
pk_trade_request          74.7      26.1      24.2      18.9       0.8    66
i_t_s_symb                60.1      21.2      19.4      15.4       0.7    66
pk_holding_history        21.0       7.5       7.0       5.4       0.3    66
pk_account_permission     19.7       6.9       6.4       5.0       0.2    66
i_hh_t_id                 15.6       5.5       5.1       3.9       0.2    66
pk_sector                  0.0      12.7       3.4       0.0       0.6    25
pk_trade_type              0.2       0.4       0.3       0.4       0.3    66
pk_exchange                0.1       0.2       0.1       0.2       0.1    66
pk_taxrate               204.2       0.1       0.1       0.1       1.8    66
pk_status_type             0.1       0.1       0.1       0.1       0.1    66
pk_watch_list              0.1       0.1       0.1       0.1       0.1    66
i_dm_s_symb                0.0       0.0       0.0       0.0       0.0    66
i_t_st_id                  0.0       0.0       0.0       0.0       0.0    66
pk_charge                  0.0       0.0       0.0       0.0       0.0     0
=====================  =======  ========  ========  ========  ========  ====

.. dbstat-tables-end

Profiles
========

Each run's profile is in ``runs/<run>/<users>/db/madrona/profile/``:
``perf.data``, ``perf.txt``, ``perf-report.txt``,
``perf-annotate.txt``, ``perf.folded`` and ``flamegraph.svg``.  The
last two are regenerated by ``flamegraph.sh`` after each run, because
the AppImage leaves them empty, see ``FIXES.rst``.  The symbol table
above comes from ``perf-report.txt``.  The flamegraphs show the same
symbols with their call paths, and ``perf-annotate.txt`` shows the
instructions of each with the most samples.

Validity
========

Every reported run was checked for rollbacks near zero except Trade
Order at about 1 percent, Trade Result within a few tenths of a
percent of Trade Order in the mix, transaction counts plausible for
the duration, a market exchange that ran to the end, and a task count
on the machine that stayed flat.  Runs made before the two harness
fixes are kept in ``unused/`` under ``*.invalid-*`` names, outside
the directories the tables are read from.

Cost
====

A 5000 customer build takes 16 minutes and a measured point 62
minutes.  The 32 point sweep is about 33 hours.
