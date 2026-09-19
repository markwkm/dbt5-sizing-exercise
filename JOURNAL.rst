=====================================
 Steps of the search, by the plan
=====================================

The tests that the plan's rule calls for, chosen from this search's
own measurements, in order, and the decision behind each.  The rule
is the specification's: a customer count is over if its measured
rate exceeds 102 percent of ``customers / 500``.  ``PLAN.rst`` holds
the decision rule and ``RESULTS.rst`` the measurements.  The actual
execution departed from these steps twice, with a probe chosen from
the first search's results and with a period under a looser rule.
``RESULTS.rst`` records those departures where they touch the
numbers.  They are not steps of the search.

1. Phase 0, 5000 customers, users 1 to 32.  The baseline from which
   the rest of the search extrapolates.  A full sweep at the minimum
   scale gives the peak rate the machine reaches with the database
   in memory, which sets the spot check, and the shape of throughput
   against users, which shows how the system behaves before the
   database size has any effect.  Over its limit at every user
   count, so the system is rule limited and the search proceeds.

2. Phase 1, 97000 customers, 16 users.  The spot check at the peak
   rate times 500, rounded up to the next Load Unit.  Under by a
   wide margin.  By the plan's rule no further user counts were
   needed.  Bracket: 5000 over, 97000 under.

3. Phase 2, 45000 customers, 16 users.  The first bisection probe,
   at the crossing interpolated from the margins at the two ends of
   the bracket.  Under by a wide margin.  By the plan's rule no
   further user counts were needed.  Bracket: 5000 over, 45000
   under.

4. Phase 3, 30000 customers, users 20, 18, 22, 16, 24, extended to
   26, 28, 32 and then 36, 40 by the edge and tie rules.  The grid
   point nearest the crossing interpolated between 5000 and 45000.
   Over: its plateau exceeds 102 percent of nominal at every user
   count.  Bracket: 30000 over, 45000 under.

5. Phase 4, 35000 customers, users 24, 22, 26, 20, 28, extended to
   32 by the edge rule.  The grid point above the over end of the
   bracket, measured to narrow the bracket to one grid step before
   refining by Load Units.  Under at every user count, and below
   the 80 percent floor.  Bracket: 30000 over, 35000 under.

6. 31000 customers, users 24, 22 and 26.  The Load Unit the
   interpolation between the margins at 30000 and 35000 names.
   Over on the second point, which is conclusive, so the sweep was
   stopped after the point already running.  Bracket: 31000 over,
   35000 under.

7. 32000 customers, users 24, 22, 26, 20, 28, extended to 32 by
   the edge rule and to 18 and 16 by the tie rule.  The Load Unit
   above the over end and adjacent to it.  Under at every user
   count, so the search is closed: 31000 over and 32000 under are
   adjacent Load Units, and 32000 is the answer, reported as
   measured, since every point lies below the nominal rate.  The
   user count reported is 18, the lowest within 3 percent of the
   best, and 16 is not within it.

8. Two replicate runs at the answer point, as the plan requires.
   They reported 62.57 and 62.53 against the sweep's 62.45, a
   spread of 0.2 percent.  The answer is 32000 customers at 18
   users, 62.45 trtps.
