===================================
 Steps of the exercise, by the plan
===================================

This file lists, in order, the tests that the plan's rule calls for
and the decision behind each one.  Each test is chosen from this
exercise's own measurements.  The rule is the specification's: a
customer count is over if its measured rate exceeds 102 percent of
``customers / 500``.  ``PLAN.rst`` holds the decision rule and
``RESULTS.rst`` the measurements.

The actual execution departed from these steps twice.  One probe was
placed from earlier measurements on this machine rather than by the
plan's rule, and for a period the exercise ran under a looser rule.
``RESULTS.rst`` records both departures where they affect the
numbers.  They are not steps of the plan.

1. Phase 0, 5000 customers, users 1 to 32.  This is the baseline
   from which the rest of the exercise extrapolates.  A full sweep
   at the minimum scale gives the peak rate the machine reaches with
   the database in memory, which sets the spot check.  It also gives
   the shape of throughput against users, which shows how the system
   behaves before database size has any effect.  Result: over its
   limit at every user count, so the system is limited by the rule
   and the exercise proceeds.

2. Phase 1, 97000 customers, 16 users.  The spot check, at the peak
   rate times 500, rounded up to the next Load Unit.  Result: under
   by a wide margin.  By the plan's rule no further user counts are
   needed.  Bracket: 5000 over, 97000 under.

3. Phase 2, 45000 customers, 16 users.  The first bisection probe,
   at the crossing interpolated from the margins at the two ends of
   the bracket.  Result: under by a wide margin.  By the plan's rule
   no further user counts are needed.  Bracket: 5000 over, 45000
   under.

4. Phase 3, 30000 customers, users 20, 18, 22, 16 and 24, extended
   to 26, 28 and 32 and then to 36 and 40 by the edge and tie rules.
   The grid point nearest the crossing interpolated between 5000 and
   45000.  Result: over, since its plateau exceeds 102 percent of
   nominal at every user count.  Bracket: 30000 over, 45000 under.

5. Phase 4, 35000 customers, users 24, 22, 26, 20 and 28, extended
   to 32 by the edge rule.  The grid point above the over end of the
   bracket, measured to narrow the bracket to one grid step before
   refining by Load Units.  Result: under at every user count, and
   below the 80 percent floor.  Bracket: 30000 over, 35000 under.

6. 31000 customers, users 24, 22 and 26.  The Load Unit named by
   interpolating between the margins at 30000 and 35000.  Result:
   over on the second point, which is conclusive, so the sweep
   stopped after the point already running.  Bracket: 31000 over,
   35000 under.

7. 32000 customers, users 24, 22, 26, 20 and 28, extended to 32 by
   the edge rule and to 18 and 16 by the tie rule.  The Load Unit
   directly above the over end.  Result: under at every user count,
   which closes the exercise.  31000 over and 32000 under are
   adjacent Load Units, so 32000 is the answer.  It is reported as
   measured, since every point lies below the nominal rate.  The
   user count reported is 18, the lowest within 3 percent of the
   best.  16 is not within 3 percent.

8. Two replicate runs at the answer point, as the plan requires.
   They reported 62.57 and 62.53 trtps against the sweep's 62.45, a
   spread of 0.2 percent.  The answer is 32000 customers at 18
   users, 62.45 trtps.
