=============================================
 Sizing TPC-E customers and users with DBT-5
=============================================

A procedure for determining, on any system, the customer count and
emulated user count that give the highest Trade-Result throughput
that the TPC-E scaling rule permits.  Worked examples come from the
machine this exercise ran on, an Amazon Web Services r5b.4xlarge
instance.  ``RESULTS.rst`` holds its numbers and ``JOURNAL.rst`` the
steps the plan produced.

Throughput is measured in Trade-Result transactions per second,
written ``trtps`` in this directory.  The specification's own unit,
``tpsE``, is the same quantity.

The question
============

Maximize ``trtps(C, U)`` subject to the specification's scaling rule.
``C`` is the configured customer count and ``U`` the number of
emulated users.  TPC-E Standard Specification revision 1.14.0
states the rule in these clauses:

* Clause 6.6.8.2: the Nominal Throughput is 2.00 tpsE for every 1000
  customer rows in the Configured Customers.
* Clause 6.6.8.3 and clause 2.6.1.4: the Scale Factor is the number
  of customer rows required per tpsE, and for Nominal Throughput it
  is 500.
* Clause 6.7.1.2: if the Measured Throughput is between 80 and 100
  percent of Nominal, the Reported Throughput is the Measured
  Throughput rounded down to two decimals.  If it exceeds Nominal by
  not more than 2 percent, the measurement may be used but the
  Reported Throughput is set to Nominal.  Outside those bounds the
  measurement is invalid and may not be reported.
* Clause 2.6.1.2: the minimum is 5000 customers, in increments of a
  1000 customer Load Unit.

A customer count ``C`` is therefore **over** if its measured rate
exceeds::

    1.02 * C / 500

and **under** otherwise.  A measured rate below ``0.8 * C / 500`` is
invalid for the opposite reason.  Where the measured rate lies
between the nominal and the tolerance, the reported rate is the
nominal, ``C / 500``, so at the crossing the answer is reported at
its nominal rate.  Stated the other way around, a measured rate
``trtps`` needs at least ``trtps * 500`` customers to be legal.

This is a constrained maximization, not a plain one.  The highest
rate the hardware can produce is the wrong answer if the database
is too small to support it, and a database larger than the rule
requires reports a lower rate, because throughput falls with
database size once the database no longer fits in memory.  The best
legal throughput is found at the smallest legal customer count, at
the point where the falling throughput curve crosses the rising
limit line.

Bounds that the specification and practicality impose:

* ``C`` is at least 5000 and a multiple of 1000.  Multiples of 5000
  are a convenient grid for the coarse phases.
* ``U`` needs an upper bound chosen in advance, or a sweep that
  keeps finding a higher peak never ends.  The bound here is 32,
  twice the logical processor count, extended past 32 only by the
  edge rule.
* The measurement duration for every reported number is 3600
  seconds, fixed in advance.  The duration rule below explains the
  choice.

``env.sh`` carries the tolerance as ``CEILING_MARGIN``, 1.02, which
``collect.sh`` and the sweep summaries use for their verdicts.

Before you start
================

The following change the answer rather than the running time, so they
are settled before the first build and not touched during the
exercise.

**Which stored function implementation.**  DBT-5 ships the
transactions as both PL/pgSQL and C functions.  Their performance
differs greatly, and the choice decides which regime the system is
in.  Decide once, configure it once, and verify after every rebuild
that the database contains the intended one.  ``build-db.sh`` loads
the C functions and counts them, and ``phase.sh`` refuses to treat a
database as built unless all 24 are present.  The customer table is
loaded early in a build, and a build that died after loading it
once passed a check that counted only customers.

**Database server configuration.**  Fix it before starting and do not
change it during the exercise.  Every result is relative to it, and a
parameter changed part way through invalidates the comparison.  The
number of connections grows with the user count, so the connection
limit must accommodate the largest user count planned.  PostgreSQL's
default settings are sized to start on almost any machine, not to run
a workload like this one well.  The starting values here come from
long-standing rules of thumb for sizing PostgreSQL, some of them
about 20 years old, which may or may not have been measured recently.
They are a rough starting point, not tuned values.
``pg-settings-start.txt`` records them.

**The harness.**  Validate it at the smallest scale with a short run
before spending hours on measurements, and validate it again after
any change to it.  A run is sound when Trade Result is within a few
tenths of a percent of Trade Order in the transaction mix, when few
Trade Results are given up on after serialization retries, and when
the machine's task count stays flat through the run.  A harness that
fails any of these reports its own limit rather than the database's.
``FIXES.rst`` describes the defects that these checks found in this
exercise.

A defect found in the harness or in these scripts is fixed, not
worked around.  Fix it on a branch, record it in ``FIXES.rst``,
rebuild whatever ships the fix, and repeat the short validation run
before continuing.  Then treat every earlier result the defect could
have affected as suspect: repeat it on the fixed harness, move the
old run to ``unused/`` under an ``.invalid-<reason>`` suffix, where
no table is read from, and reason only from the repeated run.  Every
measurement the exercise reports must come from one and the same
harness.  A result from before a fix and a result from after it are
not comparable, even when the defect appears unrelated to the scale
in question.

**Disk.**  Only one database exists at a time, since every phase
rebuilds, but the largest configuration must fit with room for the
write-ahead log.  Estimate from the size of the first build, which
is close to linear in customer count: 12 GB per 1000 customers on
this machine.  The spot check is the largest database of the
exercise and sets the disk requirement.

Then set the shared values in ``env.sh``: the data directory, the
database name, the durations, the ceiling margin, and the directory
that receives results.  Everything else is derived.

Finally, start each run on a quiet machine.  Processes left over
from a previous test continue to consume the system being measured,
and their effect grows as they accumulate.  ``env.sh`` stops a
finished test's statistics collectors before the next test starts.

Which regime the system is in
=============================

The shape of the procedure follows from one question, and a single
short run answers it.  Build the smallest legal database, 5000
customers, and measure it.

**Hardware limited.**  The achievable rate is below the limit even
at 5000 customers.  The constraint never applies.  The problem is
then a plain maximization: find where throughput peaks and report
it.

**Rule limited.**  The achievable rate exceeds the limit at 5000
customers.  The database must grow until the rule permits the rate
the machine already reaches.  The rest of this document addresses
this case, which is the case for any reasonably fast machine.  Here
5000 customers gave 193.59 trtps against a limit of 10.2, nineteen
times over.

Why the bisection variable is the ratio
=======================================

Throughput is **not** monotone in customer count.  Two effects
compete: a larger database spreads row and index contention over
more rows and pages, and a larger database extends further beyond
the memory.  The first effect wins while the database still fits in
memory, so throughput commonly rises before it falls.  Bisecting on
throughput would therefore be invalid.

The quantity to bisect on is::

    ratio(C) = max over U of trtps(C, U)
               -----------------------------
                     1.02 * C / 500

The denominator rises linearly with ``C`` while the numerator
eventually collapses, so the ratio decreases monotonically even
where throughput does not, and it crosses 1.0 exactly once.  The
collapse is driven by the disk read cost per transaction, which on
this machine was 0.01 MB with the database in memory, 3 MB with the
database at three times memory, and 196 MB at nine times memory.

**That crossing is the answer.**  Below it every configuration is
illegal.  Above it the database is larger than necessary and the
reportable rate is lower than the machine could give.  The goal is
the smallest ``C`` whose ratio is at or below 1.0.

Procedure
=========

The procedure is a sequence of phases.  A phase is one customer
count: drop and rebuild the database at that size, load the chosen
stored functions and verify them, run a short test to warm the cache
and confirm the setup, then measure one or more user counts against
that one database.  Rebuilding is by far the most expensive step, so
every user count wanted at a given size is measured while that
database exists.

Where to start the user sweep: the peak is near the logical
processor count when the database fits in memory, and at a higher
user count when it does not, because a system limited by storage
needs more concurrent requests to keep the storage busy.  Measure
the likeliest peak first: an "over" verdict then arrives on the
first point and the rest of the phase can be abandoned.

Phase 0, the baseline
---------------------

5000 customers, every user count from 1 to 32, each a full 3600
second run.  This is the baseline from which the rest of the exercise
extrapolates, and it is measured completely for that reason.  It
gives two things the later steps need: the peak rate ``trtps_max``
the machine reaches with the whole database in memory, which sets the
spot check of phase 1, and the shape of throughput against
concurrency before database size has any effect, with a profile at
each point, against which every larger scale is compared.

The limit plays no part in this phase.  At the minimum scale the
machine is expected to be over the limit from the first user, and
the verdict rules below, under which an "over" is conclusive from
one point, are not applied here.  Every user count is measured
regardless, because the object is the behavior of the system as the
user count changes, not a verdict on 5000 customers.  The only thing
the limit says at this scale is which regime the system is in, and
that is read from the peak once the sweep is complete.

Measure the ramp here as well.  Every point is a full length run,
so ``stability.sh`` reports for each one where the rate settled,
the steady mean, its scatter, and any drift.  Those numbers set the
terms for everything after: the settling time says what a short run
can and cannot show, the steady rate is what the verdicts are about,
and the noise floor is the yardstick for deciding whether two
results differ.  Here the runs settled in 5 to 9 minutes, and the
scatter over the settled part of a run matched the counting floor.

Extend past 32 users only if the edge rule demands it: if 32 users
is the best point or within 3 percent of it, measure 36 and 40.

Phase 1, the spot check at trtps_max times 500
----------------------------------------------

Once the maximum throughput is known, measure the customer count
that rate itself requires::

    C_spot = trtps_max * 500, rounded up to the next 1000

This is the customer count at which the peak rate would be exactly
legal if throughput did not fall with database size.  Throughput
does fall, steeply once the database is several times the memory,
so this point is expected to come back far under its limit, and it
bounds the answer from above.  Here 193.59 trtps put the spot check
at 97000 customers, and the probe came back under by a factor of one
hundred.

Measure one point at 16 users first, and decide from its margin
whether the scale needs more.  The verdicts are asymmetric.  A count
is over as soon as one user count exceeds the limit, but it is under
only if its best user count stays below the limit, so an "under" is a
statement about the peak, and the peak is normally found by sweeping.
The sweep can be skipped when the one point is under by more than any
peak could recover.  A system limited by storage does reach its peak
at a higher user count than a system with the database in memory,
because more concurrent requests keep the storage busier, but the
gain is tens of percent.  In earlier measurements on this machine,
50000 customers rose from 2.5 to 3.4 trtps between 8 and 16 users.  A
point one hundred times under, or twenty times under, is under at
every user count, and sweeping it would characterize the scale at a
cost of about eight hours without affecting the verdict.  Measure a
second point, at 32 users, only if the first is within a factor of
two of its limit, where the peak could decide the verdict.  The
sweeps are reserved for the scales near the crossing, where the
verdict is close and the number is reported.

Phase 1 also serves as the disk and time check: it is the largest
build the exercise will do, so it establishes both extrapolations
in the cost model.

Phase 2 onward, bisect
----------------------

Bisect the bracket on the verdict, not on throughput.  Two
refinements reduce the number of phases needed:

* Interpolate the margin ``trtps - limit`` linearly between the
  bracket ends and probe near the predicted crossing rather than the
  midpoint.  The curve is steep in places and this saves whole
  phases.
* Prefer a probe that can end the bisection outright.  If the lower
  end of the bracket is over and the probe is the next grid point
  above it, an "under" verdict makes the probe itself the answer.

Use the 5000 grid until the bracket is one grid step wide, then
multiples of 1000 inside it.  Choose probes from measured margins,
not from a theory about the hardware, and not from results measured
outside the exercise.  Here the margins named 45000 as the probe
after the spot check.  A probe taken from earlier measurements
instead has to be justified afterwards.  A bisection that narrows on
its own measurements is part of the deliverable.

The number of user counts a probe receives follows the rule stated
for the spot check.  One point, at the likeliest peak, decides an
"over" outright, and it decides an "under" whenever the margin is
beyond any peak's reach, which means a factor of two or more.  A
probe that lands closer than that is swept until its best user
count is interior, because its verdict then depends on where the
peak is.  Here 45000 was decided by one point, twenty times under,
while 30000 and 35000, near the crossing, are swept.

Phase N, refine below the grid
------------------------------

A grid of 5000 customers is convenient but arbitrary.  TPC-E
requires multiples of 1000, so once the crossing is bracketed to a
5000 wide interval, probing inside it finds a smaller legal ``C``
with a higher reportable rate.  Near the crossing the throughput
curve is flat while the limit rises steadily, so the two meet at a
shallow angle.  Decide with the interpolation before spending a
build, and expect the gain to be modest.

When to stop
------------

The exercise ends when one of these holds, so that "optimal" is a
measured claim rather than a judgment:

* The bracket has narrowed to adjacent Load Units, and the lower one
  is over while the upper one is under.  The upper one is the
  answer, reported at its nominal rate if its measured rate lies
  between the nominal and the tolerance.
* The crossing is bracketed and the interpolated gain from refining
  further is smaller than the run to run scatter.  Nothing remains
  to measure that a repeated run would not obscure.
* The bracket reaches 5000 customers still under.  The system is
  hardware limited after all.
* The bracket reaches the upper bound set for ``C`` still over.
  Report that the limit cannot be satisfied within the bound.

Record the result as it stands after each phase, so that the exercise
can be stopped early and still yield the best pair found so far.
Once the answer is found, repeat the answer point: two repeated runs
on a fresh build gave a run to run spread of 2 percent here, which is
the figure every "within 3 percent" below relies on.

Measurement rules
=================

These are the rules the exercise needed.  Each was learned by getting
something wrong without it.

Check that the run settled before believing it
-----------------------------------------------

A run does not deliver its steady rate immediately.  After a rebuild
the cache is cold, and throughput climbs for several minutes inside
the measurement interval.  This is separate from, and much longer
than, the ramp-up the harness already accounts for, which covers
only user startup.

The per-transaction logs make this directly observable.  Trade
Result is transaction type 9 and is recorded by the market exchange
emulator in ``mee/mix-me-*.log``, one line per transaction, with
the measurement clock starting at the ``START`` record in
``driver/mix-dr.log``.  ``stability.sh`` counts those by minute and
reports, per run, where the rate settled, the steady mean, its
scatter, and any drift.

Judge scatter against the counting floor, not against zero.  A one
minute bin holds about ``rate * 60`` arrivals, so even a perfectly
steady system scatters by ``100 / sqrt(rate * 60)`` percent.  At 2
trtps that floor is 9 percent and a run reads as "variable" or
"unstable" without anything being wrong.  At 190 trtps the floor is
under 1 percent.

Use the report as a gate on evidence:

* A run reported as **never-settled** has not measured steady state.
  Its number is not evidence of anything and must not be used to put
  a customer count under its limit.
* A run reported as **drifting** or **unstable** should be repeated
  before it decides anything, unless its scatter equals the counting
  floor and its verdict is far from the limit.
* A settled run understates steady state slightly, because the
  reported figure still includes the ramp.  Here the gap was 1 to 3
  percent, which matters when interpolating.
* Scatter that is periodic, with the same period and size in every
  run at a scale, is a property of the system at that scale rather
  than run to run noise, and repeating the run reproduces it.
  Record its period and its cause, and take the run's mean as the
  steady rate, provided the run spans many periods.  Here every run
  at 35000 customers alternated between a fast minute and a slow
  minute through the kernel's page cache aging, and each hour
  spanned about thirty cycles.  ``stability.sh`` judges a run that
  reads as unstable or never settled on one minute bins again on
  five minute bins, longer than the period, and reports it as
  periodic when it is stable on those.  A run whose scatter is
  counting noise does not become stable on longer bins and keeps
  its one minute verdict.
* The 600 second smoke test warms the cache only while the database
  is not far beyond memory.  At 35000 customers the first point
  after the build was still climbing after thirty minutes and never
  settled.  Treat the first point after a build as suspect at any
  scale beyond memory, and when the stability check says it never
  settled, set it aside and repeat it at the end of the phase.

Choose the duration from the measured ramp and from the checkpoints
-------------------------------------------------------------------

The ramp is the reason short runs mislead.  Earlier 300 and 600
second runs on this machine never settled, and their error grew with
database size, so every measured point in this exercise is 3600
seconds, bracketing probes included.  Shorter runs serve only to
validate scripts and warm caches, and they carry a duration suffix in
their directory names so that they cannot be mistaken for
measurements.

3600 seconds was chosen for a second reason: checkpoints.  A
checkpoint is a burst of writes, and whether the throughput of a
short run includes one depends on when the run happens to start.
The server checkpoints every 15 minutes (``checkpoint_timeout``), so
an hour contains at least four, and every measurement carries the
same checkpoint work: its steady rate does not depend on when the
last checkpoint occurred.  The specification requires the same
thing in its own clauses.  Clause 6.6.4.1 requires all work the
system performs at regular intervals to occur in full at least once
between the start of steady state and the start of the measurement
interval, and clause 6.6.3.3 requires the throughput over any ten
minute window, moved in one minute steps across steady state, to
stay within 20 percent of the reported rate.  Only a run that
contains its checkpoints can show either.

Two clauses bear on this, stated so that no run here is mistaken
for a compliant one.  Clause 6.6.5.3 requires that during the
measurement interval the database contents on durable media, the
transaction log excepted, never be more than 15 minutes older than
any committed state, and its comment says this may require
checkpointing every 7.5 minutes.  The 15 minute checkpoint interval
is set for this clause.  Clause 6.6.5.1 requires the measurement
interval to be at least two hours and entirely within steady state,
so 3600 seconds is half the compliant minimum.  These are
characterization intervals, chosen long enough to settle and to
contain the checkpoints, not reportable ones.  A compliant run would
need the two hour interval and would then contain eight or more
checkpoints.

Verdicts are asymmetric
-----------------------

The ratio is defined on the maximum over user counts, so:

* **Over** is conclusive from a single point.  One user count above
  the limit proves the maximum is above it.  Stop and move on.
* **Under** requires knowing the peak, unless the margin is beyond
  any peak's reach, as the phase 1 and phase 2 sections describe.
  Otherwise sweep user counts until the best is interior, with lower
  values on either side.

This asymmetry is what makes the exercise affordable.  Bracketing
phases cost one point each, and only the deciding phases pay for a
full sweep.

The edge rule
-------------

A phase is unfinished while its best user count is the lowest or
the highest measured.  A best point at an edge means the peak lies
outside the range tested.  Extend in that direction and measure
again.

Resolve the peak finely
-----------------------

The user count that maximizes throughput moves with database size,
and the peak is broad but not flat.  Here it was at 16 users with
the database in memory and at 24 users with the database at three
times memory, on a plateau from 22 to 40 users that a coarse sweep
would have mistaken for a peak at its first point.  Once a plateau
appears between two coarse points, fill it in at finer spacing.

Ties
----

Run to run scatter is about 2 percent, measured by repeating the
answer point.  Treat differences under 3 percent as ties and prefer
the lower user count, which holds fewer connections for the same
throughput.  Among tied counts prefer an even one, and the logical
processor count when it is among them, because it is easier to
reason about and to reproduce.  A tie does **not** satisfy the edge
rule: if the best point and an edge point are within 3 percent,
extend anyway, because a flat top may continue to rise beyond the
range measured.  Stop extending once enough points span the top to
show that it is flat: at 30000 customers, ten points across an 18
user range, with the limit far above them, were enough.

Validate every run
------------------

A run can complete and report a number that means nothing.  Check
the summary before believing it:

* Rollbacks near zero for every transaction type except Trade Order,
  which should be about 1 percent by specification.
* Transaction mix within a few tenths of a percent of the target,
  with Trade Result within a few tenths of Trade Order.  A Trade
  Result share well below Trade Order's means the market exchange
  emulator is not delivering results, and the reported rate is the
  harness's, not the database's.
* Trade Results given up on after serialization retries, which the
  summary counts as rollbacks, no more than a small fraction of a
  percent.
* The market exchange emulator ran to the end, and the machine's
  task count stayed flat through the run.
* Transaction counts plausible for the duration.

The reported throughput is a single number summarizing tens of
thousands of transactions, and it discards everything about how
they were distributed over the run.  Each mistake found in this
exercise was found by returning to that discarded detail.

Cost model
==========

Measured on this machine:

=========  ========  ==========
Customers  DB size   Build time
=========  ========  ==========
     5000     60 GB      16 min
    30000    362 GB     107 min
    31000    374 GB     118 min
    32000    387 GB     118 min
    35000    420 GB     125 min
    45000    540 GB     170 min
    97000   1170 GB     412 min
=========  ========  ==========

Database size is 12 GB per 1000 customers.  Build time is dominated
by index and foreign key creation on the largest tables rather than
by the data load, which ran at about 12 GB per minute.  A measured
point costs 62 minutes.  A phase is one build, a smoke test and one
to ten points, and the sweeps at the deciding scales are the bulk of
the cost.

Rebuilding for every customer count appears to be the obvious cost
to cut, and it cannot be cut.  The workload can be driven with fewer
active customers than the database holds, but the effect under study
is database size, so running fewer active customers against a larger
database measures the larger database.  The rebuilds are inherent to
the question.

Tooling
=======

The scripts in this directory.  All settings can be overridden from
the environment::

    env.sh             shared settings, ceiling margin included
    build-db.sh        CUSTOMERS -- rebuild, load PL/C, fix broker
    smoke.sh           CUSTOMERS -- 600 s at 16 users, warms the cache
    sweep.sh           CUSTOMERS START [STEP STOP]
    phase.sh           CUSTOMERS USERS... -- a whole phase, resumable
    collect.sh         verdict summary, then the throughput matrix
    stability.sh       per run: where the rate settled, how steady
    mee-load.sh        per run: market exchange connection load
    flamegraph.sh      regenerate perf.folded and flamegraph.svg
    results-table.sh   the RESULTS.rst throughput tables
    io-table.sh        the RESULTS.rst storage tables
    utilization-table.sh  the RESULTS.rst utilization tables
    profile-table.sh   profiles of a set of runs side by side
    dbstat-table.sh    the RESULTS.rst caching and index tables
    update-results.sh  splice all generated tables into RESULTS.rst

``phase.sh`` rebuilds only when the loaded customer count differs
from the one requested or the stored functions are missing, and it
skips user counts already measured, so a phase can be interrupted
and resumed with the same command.  ``env.sh`` sends results to
``runs/``, smoke tests to ``smoke/`` and build logs to ``build/``
under the directory of the scripts unless ``RESULTS``,
``SMOKERESULTS`` or ``BUILDLOGS`` says otherwise.  Long
phases run detached from the session harness (``setsid nohup``),
because the harness has killed background work during large loads
on a false low memory judgment.

The exercise ran as follows::

    cd ~/claude-tests/scaling2

    # Phase 0: the baseline, the full sweep at the minimum scale.
    ./phase.sh 5000 $(seq 1 32)

    # Phase 1: the spot check, at trtps_max * 500 rounded up.
    ./phase.sh 97000 16

    # The first bisection probe, from the interpolated margin.
    ./phase.sh 45000 16

    # The grid point the interpolation names, with the sweep an
    # "under" verdict needs.  Over under the specification's rule.
    ./phase.sh 30000 20 18 22 16 24 26 28 32 36 40

    # The next grid point up, then Load Units inside the interval
    # it brackets.
    ./phase.sh 35000 24 22 26 20 28

    ./update-results.sh

Record the outcome in ``RESULTS.rst`` as the exercise proceeds,
including which runs settled: the ``collect.sh`` verdict summary and
the users-by-customers matrix together, because the summary alone
hides that the best user count moves with scale.
