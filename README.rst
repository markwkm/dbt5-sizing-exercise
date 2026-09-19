=====================================
 Profiled rerun of the scaling search
=====================================

A rerun of the search recorded in ``../scaling``, with the dbt5
AppImage that captures a profile during every test.  Started
2026-09-08.  The procedure is ``PLAN.rst``.  This file records what
differs from the first search in setup, and why.

What differs from the first search
==================================

**Profile data.**  Every test passes ``--profile``.  ``dbt5 run``
samples the whole system with the Linux profiler, ``perf record -a
--call-graph dwarf -F 99``, for 20 seconds starting at the middle
of the measurement interval, and writes the capture and the files
derived from it to ``<test>/<users>/db/<host>/profile/``:
``perf.data``, ``perf.txt``, ``perf.folded``, ``flamegraph.svg``,
``perf-report.txt`` and ``perf-annotate.txt``.  The first search
captured none of this.

**Software.**  dbt5 v0.10.14-5d87f86 bundling touchstone-tools
``wip`` at 9d75d71, which carries the ts-profile fixes described in
``../PROFILING.rst``.  Verified on this machine before the first
test: a 3 second capture produced a mean stack depth of 9 frames,
which shows that the DWARF based stack unwinding works, and
``perf.data`` was owned by the user afterwards.

**Phase 0 is a full user sweep.**  5000 customers, users 1 to 32 in
steps of 1, rather than 8, 16, 24 and 32, every point at the full
3600 seconds.  It is the baseline from which the rest of the search
extrapolates: the peak rate with the database in memory sets the
spot check, and the shape of throughput against concurrency, with a
profile at every point, is the reference against which the larger
scales are read.  The first search measured this scale with 300
second runs, which were too short to settle.

What is deliberately the same
=============================

**Server configuration.**  The parameter campaign in
``../RESULTS.rst`` left the server at the values that campaign
selected, 68 GB ``shared_buffers``, 36 MB ``work_mem`` and
``effective_io_concurrency`` 16.  On the user's instruction those
were reverted before the first build to the values the original
search ran under, so that the two searches are comparable.  The
original values were taken from the ``pg_settings`` capture inside
the original runs
(``../scaling/c30000-u20/20/db/madrona/dbstat/params.csv``), not from
notes.  After the restart the live server differed from that capture
in nothing but the three logging settings below.
``pg-settings-start.txt`` records it:

============================ ==========
``shared_buffers``           32 GB
``effective_cache_size``     40 GB
``work_mem``                 64 MB
``effective_io_concurrency`` 300
``random_page_cost``         1.0
``jit``                      off
``max_connections``          1000
``log_statement``            none
``log_connections``          off
``log_disconnections``       off
============================ ==========

The original search ran with ``log_statement = 'all'``, which wrote
every statement to a file on the database's device at several GB per
hour and was identified in ``../PLAN.rst`` as a sustained write load
and a per-statement cost.  The user chose to keep it off here, along
with connection and disconnection logging, as the parameter campaign
did.  That is the one deliberate difference from the original
configuration, and the direction of its effect is known: this search
should run somewhat faster than the original at the same point.
Nothing is changed during this search.

**Durations.**  3600 seconds for every measured point, as in the
first search.  The 1200 second runs made before the sweep, to
validate that the scripts and the profile capture work, all fell to
the harness defects described in ``FIXES.rst`` and are kept in
``unused/``.  A run of any other duration than 3600 seconds carries
a ``-d<seconds>`` suffix on its directory name, and ``collect.sh``
prints a ``*`` marker next to it, so that it is never mistaken for
a reportable run.

Harness defects
===============

Two defects in dbt5 and one in the AppImage were found by the
validation runs and are recorded, with their fixes, in
``FIXES.rst``.

Layout
======

Three documents: ``PLAN.rst`` says how the decisions are made,
``RESULTS.rst`` what the measurements show, and ``JOURNAL.rst`` the
steps of the search in the order the plan calls for them.

The scripts, the documents and the charts are at the top of this
directory, and everything the runs produced is in four
subdirectories.  ``runs/`` holds the results, one directory per
test, named as in the first search:
``c<customers>-u<users>[-d<seconds>]``, and the replicate runs of
the answer points in ``runs/replicates/``.  ``smoke/`` holds the
smoke tests
the same way, as ``c<customers>-smoke[-d<seconds>]``, with those of
the replicate builds in ``smoke/replicates/``.  ``build/`` holds
the build logs,
``c<customers>-build.log``, and the loader's own output.  ``logs/``
holds the output of the driver scripts, ``phase0-validate.log``,
``phase0-sweep.log`` and their successors, and the lock captures
taken while the harness defects were found.  ``unused/`` holds
what no table or figure is read from: the runs and smoke tests set
aside under an ``.invalid-<reason>`` suffix, the 29000 customer
probe that was set aside with the 20 percent allowance, and earlier
versions of the survey chart.  The scripts are the ones
from ``../scaling`` with three changes, listed at the top of
``env.sh``, and ``env.sh`` sends results to ``runs/``, smoke tests
to ``smoke/`` and build logs to ``build/`` unless ``RESULTS``,
``SMOKERESULTS`` or ``BUILDLOGS`` is set.
``relation-sizes-32000.txt`` holds the size of every TPC-E table
and index on the 32000 customer database, and
``dbstat-index-use.txt`` the index scans of every run, both read by
``dbstat-table.sh`` for the caching and index section of
``RESULTS.rst``.

Charts, drawn by gnuplot from ``throughput-<customers>.dat``:
``throughput-5000.png`` is the bar chart of the phase 0 sweep,
``throughput-survey-<seq>.png`` the line chart of every customer
count measured with its limit line, and
``throughput-crossing-<seq>.png`` the same for the customer counts
around the crossing, 30000 to 35000, with the replicate runs of the
answer point.  ``<seq>`` is the gnuplot color sequence, ``podo`` or
``default``, and the ``.gnuplot`` files of the same names draw them.

Reading the profiles
====================

``flamegraph.svg`` is interactive in a browser.  ``perf-report.txt``
is the same data as a table, with two percentages per symbol: the
share of samples in the symbol and everything it called (children),
and the share in the symbol itself (self).  ``perf.folded`` is the
input to both and is the file to compare between two user counts.
All three describe time on the processor only.  A backend blocked on
input/output or on a lock does not appear in them, which matters
once the database no longer fits in memory.
