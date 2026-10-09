==================================================
 Profiled DBT-5 customer and user sizing exercise
==================================================

A sizing exercise to find the TPC-E customer count and emulated user
count that give the highest Trade Result throughput the TPC-E
scaling rule permits, run with DBT-5 against PostgreSQL 18.4 on an
Amazon Web Services r5b.4xlarge instance, with a profile captured
during every test.  Started 2026-09-08.  The procedure is
``PLAN.rst``.  This file describes how the tests were set up, and
why, and where their output is.

Setup
=====

**Profile data.**  Every test passes ``--profile``.  ``dbt5 run``
samples the whole system with the Linux profiler, ``perf record -a
--call-graph dwarf -F 99``, for 20 seconds starting at the middle
of the measurement interval, and writes the capture and the files
derived from it to ``<test>/<users>/db/<host>/profile/``:
``perf.data``, ``perf.txt``, ``perf.folded``, ``flamegraph.svg``,
``perf-report.txt`` and ``perf-annotate.txt``.

**Software.**  dbt5 v0.10.14-5d87f86, bundling touchstone-tools
``wip`` at 9d75d71.

**Phase 0 is a full user sweep.**  5000 customers, users 1 to 32 in
steps of 1, every point at the full 3600 seconds.  It is the
baseline from which the rest of the exercise extrapolates: the peak
rate with the database in memory sets the spot check, and the shape
of throughput against concurrency, with a profile at every point,
is the reference against which the larger scales are read.

**Server configuration.**  PostgreSQL's default settings are sized
to start on almost any machine, not to run a workload like this one
well, so the server is not run at its defaults.  The starting values
come from long-standing rules of thumb for sizing PostgreSQL, some
of them about 20 years old, which may or may not have been measured
recently.  They are a rough starting point, not tuned values.
``pg-settings-start.txt`` records every setting that was not at its
default when the exercise started.  These are the ones that bear
most on the results:

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

Statement logging is off because ``log_statement = 'all'`` writes
every statement to a file at several GB per hour, which is both a
sustained write load and a per-statement cost on every backend.
Connection and disconnection logging are off with it.
``log_lock_waits`` and ``log_temp_files = 0`` are on.

No setting is changed during the exercise.

**Durations.**  3600 seconds for every measured point.  The 1200
second runs made before the sweep, to validate that the scripts and
the profile capture work, all fell to the harness defects described
in ``FIXES.rst`` and are kept in ``unused/``.  A run of any other
duration than 3600 seconds carries a ``-d<seconds>`` suffix on its
directory name, and ``collect.sh`` prints a ``*`` marker next to
it, so that it is never mistaken for a reportable run.

Harness defects
===============

The validation runs found two defects in dbt5 and one in the
AppImage.  ``FIXES.rst`` describes each one and its fix.

Layout
======

Three documents describe the exercise.  ``PLAN.rst`` says how the
decisions are made, ``RESULTS.rst`` what the measurements show, and
``JOURNAL.rst`` records the steps of the exercise in the order the
plan calls for them.

The scripts, the documents and the charts are at the top of this
directory.  Everything the runs produced is in these
subdirectories:

``runs/``
    One directory per test, named
    ``c<customers>-u<users>[-d<seconds>]``.  The replicate runs of
    the answer points are in ``runs/replicates/``.

``smoke/``
    One directory per smoke test, named
    ``c<customers>-smoke[-d<seconds>]``.  The smoke tests of the
    replicate builds are in ``smoke/replicates/``.

``build/``
    The database build logs, ``c<customers>-build.log``, and the
    loader's own output, ``EGenLoaderFrom<first>To<last>.log``.

``logs/``
    The output of the driver scripts, one file per phase, such as
    ``phase0-sweep.log`` and ``phase8-32000.log``, and the lock
    captures taken while the harness defects were found.

``unused/``
    Everything that no table or chart reads: the runs and smoke
    tests set aside under an ``.invalid-<reason>`` suffix, the
    29000 customer probe made under the 20 percent allowance that
    was withdrawn on 2026-09-11, and earlier versions of the survey
    chart.

``env.sh`` sends results to ``runs/``, smoke tests to ``smoke/`` and
build logs to ``build/`` unless ``RESULTS``, ``SMOKERESULTS`` or
``BUILDLOGS`` is set.

Two data files at the top of the directory are read by
``dbstat-table.sh`` for the caching and index section of
``RESULTS.rst``.  ``relation-sizes-32000.txt`` holds the size of
every TPC-E table and index in the 32000 customer database, and
``dbstat-index-use.txt`` holds the index scans of every run.

Charts
======

gnuplot draws the charts from ``throughput-<customers>.dat``:

``throughput-5000.png``
    A bar chart of the phase 0 sweep.

``throughput-survey-<seq>.png``
    A line chart of every customer count measured, each with its
    limit line.

``throughput-crossing-<seq>.png``
    The same for the customer counts around the crossing, 30000 to
    35000, with the replicate runs of the answer point.

``<seq>`` is the gnuplot color sequence, ``podo`` or ``default``,
and the ``.gnuplot`` files of the same names draw them.

Reading the profiles
====================

``flamegraph.svg`` is interactive in a browser.  ``perf-report.txt``
holds the same data as a table, with two percentages per symbol:
the share of samples in the symbol and everything it called
(children), and the share in the symbol itself (self).
``perf.folded`` is the input to both, and it is the file to compare
between two user counts.

All three files describe time spent on a processor only.  A backend
that is blocked on input/output or on a lock does not appear in
them.  This matters once the database no longer fits in memory.
