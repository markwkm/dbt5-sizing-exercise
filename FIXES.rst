============================================
 Harness defects found in the profiled rerun
============================================

What the validation runs found wrong with the harness before any
measurement was trusted, what caused it, and what was done.  The
setup is in ``README.rst`` and the procedure in ``PLAN.rst``.

A harness limit found by the validation run
============================================

The first 1200 second validation run ended with MarketExchangeMain
aborting 1112 seconds into the measurement interval::

    terminate called after throwing an instance of 'std::logic_error'
      what():  basic_string: construction from null is not valid

Two defects in dbt5 combined to produce that, and neither is a
property of the system under test.

**Trade Results were delivered one at a time.**  The Market Exchange
sent every Trade Result and Market Feed to the Brokerage House over
one connection, one synchronous round trip at a time under a mutex,
and each round trip lasts as long as the Brokerage House's database
transaction.  At 5000 customers and 16 users Trade Orders arrived at
about 200 per second and that one connection delivered about 74
Trade Results per second.  Every undelivered Trade Result is a
detached thread waiting for the mutex, so the process grew by about
130 threads a second.  The task count reported by sar, the system
activity reporter, climbed from 366 to 144171 over the run, and the
last sample before the abort was just under the control group's
process limit of 152784, at which pthread_create fails.  The 600
second smoke test reached 74146 tasks and stopped before the limit.

**A failed pthread_create aborted instead of being reported.**
CThreadErr defaulted its location to NULL and handed it to CBaseErr,
which stores it in a std::string.  Constructing one from NULL throws
std::logic_error out of the exception's own constructor, so the
handler for CThreadErr never ran and the process terminated with no
record of what had failed.

**This also affects the first search's 5000 customer numbers.**  Its
300 second runs at 8, 16, 24 and 32 users reported Trade Result at
8.8, 3.9, 3.3 and 2.8 percent of the mix against 10.2 to 11.0 for
Trade Order, where a valid run has the two nearly equal, as the
25000 and 30000 customer runs did at 9.87 percent.  The rates
reported there were the delivery rate of one connection, not the
database's, and the runs completed only because 300 seconds was too
short to reach the process limit.  The "over" verdicts they
supported still hold, since the true rate is higher still.  The
database also ended each of these runs with every undelivered Trade
Result's trade left in the submitted state: 139064 of them after the
two validation runs.

**Fix.**  dbt5 branch ``mee-deliver-concurrently``, three commits on
top of ``wip`` at 5d87f86:

=========  =======================================================
e9cdaeb    give a thread error a location that can be stored
71eacba    deliver Trade Results and Market Feeds concurrently: a
           pool of 16 connections to the Brokerage House, each
           delivery taking a free one, and a lock on the response
           time and error logs now written from several threads
9d95a89    make the connection count an option: ``-n`` on
           MarketExchangeMain and ``--mee-connections`` on dbt5
           run, test-user-scaling and test-db-parameter, default
           still 16
=========  =======================================================

The AppImage built from it, ``bin/dbt5``, reports
v0.10.14-1b8c1e0.  That is the hash 71eacba had before its commit
message and one comment were reworded on the user's review.  The
code is identical.  9d95a89 came after the build and is not in the
binary, which changes nothing, since the default it introduces is
the constant the binary has.  The AppImage bundles the same
touchstone-tools commit as before.  ``env.sh`` puts ``bin`` first
on the path, so every run in this directory uses it and the
AppImage in ``~/.local/bin`` is untouched.  The two runs made
before the fix are kept in ``unused/`` as
``*.invalid-mee-serialized``, outside the directories the tables
are read from.  The
Brokerage House opens a thread and a database connection per pooled
connection, so 16 idle backends appear that were not there before.

**Also found, not fixed in dbt5.**  ``ts profile`` writes
``perf.data``, ``perf.txt``, ``perf-report.txt`` and
``perf-annotate.txt`` correctly, but ``perf.folded`` and
``flamegraph.svg`` are written empty.  The AppImage exports
``PERL5LIB`` pointing at its bundled perl 5.28 modules, and
``stackcollapse-perf.pl`` runs under the host's ``/usr/bin/perl``
5.40 through its shebang line, which then loads the 5.28
``warnings.pm`` and fails to compile.  The bundled perl itself
cannot find ``strict.pm`` because its module path was not
relocated.  Running the same script with the host perl and no
``PERL5LIB`` folds the 80 MB ``perf.txt`` in four seconds, so the
flamegraphs are regenerated after each run from the retained
``perf.txt``.

A second defect, exposed by the first fix: serializable conflicts on broker
===========================================================================

With Trade Results delivered concurrently, the fresh 5000 customer
database produced PostgreSQL serialization failures, ``could not
serialize access due to read/write dependencies among
transactions``, at 33000 to 48000 failed attempts per minute during
a 16 user run, and the Brokerage House, which retries a transaction
ten times before giving up, gave up on 14 percent of Trade Results.
A run like that is invalid: the Trade Results given up on count as
rollbacks and their trades stay in the submitted state.

The mechanism, from ``pg_locks`` sampled during the runs and the
statements named in the failures.  Trade Result is the one
transaction dbt5 runs at the serializable isolation level, and every
Trade Result updates one row of ``broker``.  At 5000 customers the
50 broker rows fit in a single page, so the planner reaches the row
with a sequential scan, and under serializable isolation a sequential
scan takes a predicate lock on the whole relation.  Each Trade
Result in progress therefore holds a read lock on all of ``broker``
while writing one row of it, so every pair of concurrent Trade
Results conflicts in both directions, and any three of them form the
pattern of dependencies, called a dangerous structure in the
PostgreSQL documentation, that makes PostgreSQL abort one of them.
The statement executing at the final failure was the broker update
in 11036 of about 13500 transactions given up on.  The market
exchange emulator with its single connection never had two Trade
Results in progress at once, which is why the first search never
saw this.

The scale matters.  At 10000 customers and above ``broker`` spans
more than one page and the planner uses its primary key index, whose
predicate locks cover the row read and the index page, so the
conflicts are only those between Trade Results that touch the same
broker.  The failure rate is a property of the smallest scale alone.

**Fix, in this campaign's build rather than in dbt5.**  ``broker`` is
given a fill factor of 10 and rewritten, so its 50 rows spread over
about seven pages and the planner takes the index, as it would at any
larger scale.  A fill factor is a physical storage choice, changes no
data and no query, and TPC-E leaves such choices to the sponsor.
``build-db.sh`` does it after loading the stored functions, and it
was applied by hand to the database in use before the sweep.  The
runs made before it are kept in ``unused/`` as
``*.invalid-broker-seqscan``.

The one 16 user run that did not show the high failure rate, kept
as ``unused/c5000-u16-d1200.invalid-polluted-db``, ran on the
database the
crashed runs had polluted, and it is not known which property of
that state prevented the failures.  It is not used for anything.
