# Refactor behavioral baseline

Recorded on September 13, 2026, before the maintainability refactor begins.

## Source revision

- Branch: `main`
- Commit: `5923adbbc90e5002152524ad4dfc3faccbf18381`
- Commit subject: `Add bonus and midpoint dash states`
- Upstream comparison when recorded: three local commits ahead of `origin/main` at `7cf12da`
- Garmin source tree: clean
- Unrelated untracked matrix-development files and `node_modules` were present and left untouched

This commit is the behavior-preserving comparison point for the refactor. Each
refactor phase should be compared with this revision unless a later product
change is explicitly approved as a new baseline.

## Automated validation

Environment:

- Connect IQ SDK: `9.2.0`
- Simulator target: `edge840`
- Test build: passed
- Complete simulator suite: **54 passed, 0 failed, 0 errors**

The passing suite covers the established daily-distance scenarios, weekly and
month-end closeout, ETA and recent-pace behavior, repeating distance and
elevation bonuses, first-reading milestone catch-up and repeat prevention,
alert-setting behavior, Garmin week-start handling, rest weekdays, long days,
weekday-limit state used by the display marker, and configurable long-day targets.

## Edge 840 ride validation reported before the refactor

Passed on a physical Edge 840:

- Distance progress dashes, including yellow current-dash and blue future-dash states
- Elevation progress-dash visual layout
- Distance halfway notification
- Elevation halfway notification
- Distance goal-complete notification
- Distance bonus behavior, including blue dashes and outlined completed dashes
- Elevation bonus behavior
- Configurable long-day behavior observed with an 80-mile distance target and a 4,500-foot elevation target

Still pending physical-ride validation:

- Elevation goal-complete notification
- Elevation progress behavior across a complete riding goal, beyond its visual check

The elevation goal-complete artwork and dispatch path were exercised in the
Edge 840 simulator, but that does not replace a physical ride test.

## Refactor validation rule

The refactor must not intentionally change product behavior. After each phase,
the complete simulator suite must remain green. Changes to ride state, alerts,
bonus flow, or rendering also require the applicable Edge 840 regression checks
before that behavior is considered validated.

## Positional contracts locked by characterization tests

The following application-owned arrays cross class or subsystem boundaries.
Their current length, ordering, and values are covered before replacement with
named state types:

| Producer | Current positional contract |
| --- | --- |
| `GoalStore.getGoals()` | `[year, month, week]` |
| `GoalCalculator.scheduleCounts()` | `[weekday slots, ordinary weekend slots, long-day slots]` |
| `GoalCalculator.scheduledPeriodTarget()` | `[target, weekday-limit flag]` |
| `GoalCalculator.scheduledElevationTarget()` | `[target, weekday-limit flag]` |
| `GoalCalculator.calculateScheduledAutomaticGoal()` | `[target, weekday-limit flag, today-available flag]` |
| `GoalCalculator.distanceStateForToday()` | `[remaining, target, completed today, original automatic target, weekday-limit flag, today-available flag]` |
| `GoalCalculator.elevationStateForToday()` | `[remaining, target, weekday-limit flag]` |
| `EtaTrendEstimator.update()` | `[trend state, difference in minutes]` |

Garmin framework arrays such as `[view, delegate]`, picker values, point
coordinates, and ordinary collections are not application-owned state tuples
and are intentionally outside this refactor.

After adding these characterization tests, the Edge 840 test build passed and
the expanded simulator suite passed **62 of 62 tests**.

## Important scenarios preserved by the suite

- Established distance scenarios S1, S2, and S3
- Weekly closeout and overlapping month-end closeout using the larger remainder
- Monday- and Sunday-based configured week boundaries
- Rest-weekday redistribution, exhausted weekday ride slots, and five-rest-day weekends
- Default and custom long-day distance and elevation targets
- Weekday distance/elevation limits, limit flags, and weekend redistribution
- Overall-average pace fallback, rolling five-mile pace, paused-time exclusion, and 15-minute ETA trends
- Automatic and custom distance/elevation bonuses, overshoot carryover, repeated blocks, and repeat prevention
- Halfway and goal-complete crossings, first-reading catch-up, disabled goals, and repeat prevention
- All Alerts cascading to each individual alert setting

## Device-only visual and interaction contracts

The unit suite proves state calculations and transitions, but it does not prove
pixel placement, Garmin font rendering, native alert presentation, touch input,
or visibility while riding. Preserve these contracts during the refactor and
recheck them on an Edge 840 whenever their rendering or state flow changes.

### Main data-field screen

- The field remains inside Garmin's native cycling activity and does not replace
  or control the activity, native menus, navigation, or alerts.
- The vertical layout remains distance 37%, ETA 26%, and elevation 37%.
- Required distance and elevation sections retain black backgrounds so Garmin's
  red traffic and road-hazard alerts remain visible.
- Required-goal side rails remain narrow: red below 75%, white from 75% through
  99.9%, and green at completion.
- The ETA background remains green when ahead, black while measuring or on pace,
  and red when behind. Its time remains `00H:00M`, with `AHEAD`, `ON PACE`, or
  `BEHIND` trend labeling.
- A capped weekday value retains the trailing `*`; bonus values do not show the
  weekday-limit marker.

### Distance and elevation progress dashes

- Seven equal-width positions represent the goal; the center position alone is
  split into two halves representing 1/14 of the goal each. Every other dash
  represents 1/7 of the goal.
- For required goals, a completed dash is green. The current dash changes to
  yellow when its block is halfway complete; it becomes green when complete and
  the next dash becomes current.
- For bonus goals, incomplete dashes are blue and completed dashes are green
  with black outlines. Bonus dashes do not use the required-goal yellow state.
- Accepted bonus sections remain green and omit the required-goal status rails.

### Prompts and alerts

- Distance and elevation bonus prompts remain full-screen yes/no choices and
  repeat after each completed accepted block until declined or the ride stops.
- Distance and elevation halfway alerts retain their distinct Garmin-style
  distance and climbing iconography.
- Goal-complete and bonus-complete alerts retain the bundled full-screen distance
  or elevation artwork, correct title, zero-remaining value, system unit label,
  and optional tone behavior.
- Connect IQ alerts remain subject to the rider enabling Cycling Goals under the
  Edge activity profile's native Connect IQ alert setting.
- Alert duration remains Garmin-controlled unless a separate product change is
  approved; the current `DataField.showAlert()` API call has no duration input.

### Current device evidence

- Physical Edge 840 pass: daily distance yellow current-dash behavior.
- Physical Edge 840 pass: distance bonus blue/green outlined-dash behavior.
- Physical Edge 840 pass: distance halfway, elevation halfway, and distance
  goal-complete alerts.
- Physical Edge 840 pass: distance progress bar and bonus flows for distance and
  elevation.
- Visual-only pass: elevation progress bar appearance.
- Simulator-only pass: elevation goal-complete alert artwork and dispatch path.
- Still requires a physical ride: elevation goal-complete alert and elevation
  progress through a complete riding goal.

## Baseline acceptance criteria

- [x] The immutable comparison revision and validation environment are recorded.
- [x] Every application-owned positional result exchanged between components is
  documented by producer, array length, index order, and meaning.
- [x] A characterization test asserts every position in each of those contracts.
- [x] Established calculation, scheduling, pace, alert, and bonus scenarios
  remain represented in the regression suite.
- [x] Device-only visual and interaction contracts are recorded separately from
  behaviors that automated tests can prove.
- [x] Real-device passes, simulator-only evidence, and pending physical checks
  are clearly distinguished.
- [x] The complete Edge 840 simulator suite passes: 62 passed, 0 failed, 0 errors.
- [x] The normal Edge 840 release build succeeds.
- [x] No production behavior or product setting was changed by this baseline work.
- [x] Unrelated untracked matrix files and `node_modules` remain untouched.

## Refactor progress through subtask 05

Completed implementation stages:

- Subtask 02 introduced named distance-goal, goal-state, scheduled-target, and
  schedule-count classes without changing behavior.
- Subtask 03 migrated the scheduling helpers from positional arrays to
  `ScheduleCounts`, `ScheduledTarget`, and `ScheduledAutomaticTarget`.
- Subtask 04 migrated stored distance goals, public `GoalCalculator` results,
  settings callers, tests, and the ride view to named fields.
- Subtask 05 extracted required-goal, bonus-offer, accepted repeating-bonus,
  declined-bonus, ride-ended, and ride-reset transitions into `RideGoalState`.

Validation after subtask 05:

- Edge 840 test build: passed.
- Complete simulator suite: **75 passed, 0 failed, 0 errors**.
- Normal Edge 840 release build: passed.
- The separate Edge 840 regression ride required for ride-state and bonus-flow
  changes remains pending; simulator success does not replace that device check.

## Refactor progress through subtask 09

Completed implementation stages:

- Subtask 06 consolidated distance and elevation halfway/completion detection
  in `MilestoneTracker` and consolidated alert/tone dispatch in the ride view.
  First-reading catch-up, completion-before-halfway behavior, disabled alerts,
  and repeat prevention remain covered by tests.
- Subtask 07 moved all main-screen, ETA, progress-dash, status-rail, and bonus-
  prompt drawing into `CyclingGoalsRenderer`, driven by a named
  `CyclingGoalsScreenState`. `CyclingGoalsView` now coordinates ride input,
  state transitions, alerts, and rendering rather than drawing directly.
- Subtask 08 centralized all 13 goal-setting labels, menu details, picker
  titles, ranges, steps, AUTO/NO LIMIT labels, unit conversions, loads, and
  saves in `GoalSettingCatalog`.
- Subtask 09 routed current time and Garmin activity-history access through
  `GoalRuntime`, with injectable providers and deterministic fixed-date and
  same-day-history tests.

Validation after subtask 09:

- Edge 840 test build: passed.
- Complete simulator suite: **87 passed, 0 failed, 0 errors**.
- The renderer preserves the recorded 37% / 26% / 37% layout, status rails,
  colors, limit asterisks, progress dashes, and bonus prompt coordinates.
- Normal Edge 840 release build: passed.
- The required physical Edge 840 regression ride remains pending at this
  checkpoint; automated validation cannot prove the device-only visual and
  interaction contracts.

## Refactor progress through subtask 10

- Replaced the private five-position activity-history totals array with
  `HistoryTotals` and named year, month, week, today, and used-weekday fields.
- Replaced `EtaTrendEstimator.update()`'s `[trend, minutes]` tuple with the
  named `EtaTrendState` result and migrated its view and test consumers.
- Removed production-unused compatibility entry points
  `remainingForToday()`, `remainingElevationForToday()`, and
  `calculateAutomaticGoal()`. The S1, S2, S3, and month-end tests now exercise
  the scheduled production calculation directly.
- Moved halfway and completion threshold detection fully into
  `MilestoneTracker`, removing the obsolete `GoalCalculator` alert helpers.
- Removed the goal-setting catalog's positional fallback. Remaining numeric
  indexes are limited to Garmin framework arrays, ordered-list assertions, and
  internal time-series collections rather than cross-component state tuples.

Validation after subtask 10:

- Edge 840 test build: passed.
- Complete simulator suite: **81 passed, 0 failed, 0 errors**. The count changed
  from 87 because ten legacy-helper tests were replaced by four equivalent
  `MilestoneTracker` behavior tests; no behavioral scenario was dropped.
- Normal Edge 840 device build: passed.
- `git diff --check`: passed.
- No product behavior, settings, or rendering contract was intentionally
  changed. The physical Edge 840 regression ride remains pending.

## Refactor validation through subtask 11

The complete automated validation matrix passed on September 14, 2026:

| Validation | Result |
| --- | --- |
| Edge 840 test build | Passed |
| Edge 840 simulator suite | **81 passed, 0 failed, 0 errors** |
| Edge 840 device build | Passed |
| Edge 1040 device build | Passed |
| Edge 1050 device build | Passed |
| `git diff --check` | Passed |

The manifest product IDs `edge840`, `edge1040`, and `edge1050` cover the three
supported Edge model families documented by the project, including the 840
Solar and 1040 Solar variants. Build artifacts remained in `/private/tmp` and
were not added to the repository or copied to the connected device.

Compiler output contained only the existing test-fixture superclass warnings
and automatic launcher-icon scaling warnings for Edge 840 and Edge 1050. No
compiler error occurred. The device-only regression checks remain assigned to
subtask 12 and are not implied by this automated matrix.
