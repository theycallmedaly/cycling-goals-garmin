# Cycling Goals for Garmin

A Garmin Edge Connect IQ data field that answers one question during a ride: **how many miles remain for today?**

## Distance-only MVP

The rider configures yearly, monthly, weekly, and baseline daily distance goals using the Edge's up/down controls. The field uses cycling activity history and the current ride's elapsed distance to calculate today's remaining target.

The default target for today is the largest of the baseline daily goal and the daily averages required to finish the yearly, monthly, and weekly goals.

On Sunday, the default includes all distance still required to close the weekly goal. If Sunday falls within the final five calendar days of the month, it also includes all distance required to close the monthly goal. Because a ride counts toward both periods, the larger remainder is used rather than adding them.

Completed rides earlier today and the current ride are subtracted from today's target. The displayed value never falls below zero.

Elevation goals are intentionally paused because Connect IQ's activity-history records expose distance but not historical elevation gain.

## Current interface

```text
REMAINING FOR TODAY

0.0

MILES
```

If goals are missing, the data field directs the rider to its standard Settings screen. That screen always remains available for updating all four distance goals.

## Supported devices and prerequisites

- Edge 540 / 540 Solar
- Edge 840 / 840 Solar
- Edge 1040 / 1040 Solar
- Edge 1050
- Connect IQ API 5.2.2 or newer
- Garmin Connect IQ SDK and a developer key for local builds

This is an early MVP implementation. It has not yet been compiled because the Garmin Connect IQ SDK is not installed in the development environment.
