=========================================
 Harness defects found during validation
=========================================

This file records what the validation runs found wrong with the
harness before any measurement was trusted, what caused each defect,
and what was done about it.  The setup is in ``README.rst`` and the
procedure in ``PLAN.rst``.

A harness limit found by the validation run
===========================================

The first 1200 second validation run ended with MarketExchangeMain
aborting 1112 seconds into the measurement interval::

    terminate called after throwing an instance of 'std::logic_error'
      what():  basic_string: construction from null is not valid

Two defects in dbt5 combined to produce this abort.  Neither is a
property of the system under test.

**Trade Results were delivered one at a time.**  The Market Exchange
sent every Trade Result and Market Feed to the Brokerage House over
one connection, one synchronous round trip at a time under a mutex.
Each round trip lasts as long as the Brokerage House's database
transaction.  At 5000 customers and 16 users, Trade Orders arrived at
about 200 per second, and the one connection delivered about 74
Trade Results per second.  Every undelivered Trade Result is a
detached thread waiting for the mutex, so the process grew by about
130 threads a second.  The task count reported by sar, the system
activity reporter, climbed from 366 to 144171 over the run.  The
last sample before the abort was just under the control group's
process limit of 152784, at which pthread_create fails.  The 600
second smoke test reached 74146 tasks and ended before the limit.

**A failed pthread_create aborted instead of being reported.**
CThreadErr defaulted its location to NULL and passed it to CBaseErr,
which stores it in a std::string.  Constructing a std::string from
NULL throws std::logic_error out of the exception's own constructor.
The handler for CThreadErr therefore never ran, and the process
terminated with no record of what had failed.

**Effect on the database.**  The two validation runs left the trade
of every undelivered Trade Result in the submitted state, 139064
trades in all.

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

The AppImage built from this branch, ``bin/dbt5``, reports
v0.10.14-1b8c1e0.  1b8c1e0 is the hash 71eacba had before its
commit message and one comment were reworded on review.  The code is
identical.  9d95a89 came after the build and is not in the binary.
This changes nothing, because the default it introduces is the
constant the binary already has.  The AppImage bundles the same
touchstone-tools commit as before.

``env.sh`` puts ``bin`` first on the path, so every run in this
directory uses this AppImage, and the AppImage in ``~/.local/bin``
is untouched.  The two runs made before the fix are kept in
``unused/`` as ``*.invalid-mee-serialized``, outside the directories
the tables are read from.  The Brokerage House opens a thread and a
database connection for each pooled connection, so 16 idle backends
appear that were not there before.

**Also found, not fixed in dbt5.**  ``ts profile`` writes
``perf.data``, ``perf.txt``, ``perf-report.txt`` and
``perf-annotate.txt`` correctly, but writes ``perf.folded`` and
``flamegraph.svg`` empty.  The AppImage exports ``PERL5LIB`` pointing
at its bundled perl 5.28 modules.  ``stackcollapse-perf.pl`` runs
under the host's ``/usr/bin/perl`` 5.40 through its shebang line,
loads the 5.28 ``warnings.pm``, and fails to compile.  The bundled
perl cannot be used instead, because its module path was not
relocated and it cannot find ``strict.pm``.  Running the same script
with the host perl and no ``PERL5LIB`` folds the 80 MB ``perf.txt``
in four seconds, so the flamegraphs are regenerated after each run
from the retained ``perf.txt``.

A second defect, exposed by the first fix: serializable conflicts on broker
===========================================================================

With Trade Results delivered concurrently, the fresh 5000 customer
database produced PostgreSQL serialization failures, ``could not
serialize access due to read/write dependencies among
transactions``, at 33000 to 48000 failed attempts per minute during
a 16 user run.  The Brokerage House retries a transaction ten times
before giving up, and it gave up on 14 percent of Trade Results.  A
run like that is invalid, because the Trade Results given up on
count as rollbacks and their trades stay in the submitted state.

The mechanism was established from ``pg_locks``, sampled during the
runs, and from the statements named in the failures.  Trade Result
is the one transaction dbt5 runs at the serializable isolation
level, and every Trade Result updates one row of ``broker``.  At
5000 customers the 50 broker rows fit in a single page, so the
planner reaches the row with a sequential scan.  Under serializable
isolation, a sequential scan takes a predicate lock on the whole
relation.  Each Trade Result in progress therefore holds a read lock
on all of ``broker`` while it writes one row of it.  Every pair of
concurrent Trade Results conflicts in both directions, and any three
of them form the pattern of dependencies, called a dangerous
structure in the PostgreSQL documentation, that makes PostgreSQL
abort one of them.  The statement executing at the final failure was
the broker update in 11036 of about 13500 transactions given up on.
With a single connection, the Market Exchange never had two Trade
Results in progress at once, so this defect stayed hidden until the
first fix made delivery concurrent.

The scale matters.  At 10000 customers and above, ``broker`` spans
more than one page and the planner uses its primary key index.  The
index's predicate locks cover only the row read and the index page,
so the only conflicts are between Trade Results that touch the same
broker.  The high failure rate is a property of the smallest scale
alone.

**Fix, in this exercise's database build rather than in dbt5.**
``broker`` is given a fill factor of 10 and rewritten, so its 50
rows spread over about seven pages and the planner takes the index,
as it would at any larger scale.  A fill factor is a physical
storage choice.  It changes no data and no query, and TPC-E leaves
such choices to the sponsor.  ``build-db.sh`` applies it after
loading the stored functions, and it was applied by hand to the
database in use before the sweep.  The runs made before it are kept
in ``unused/`` as ``*.invalid-broker-seqscan``.

The one 16 user run that did not show the high failure rate is kept
as ``unused/c5000-u16-d1200.invalid-polluted-db``.  It ran on the
database that the crashed runs had polluted, and it is not known
which property of that state prevented the failures.  It is not used
for anything.
