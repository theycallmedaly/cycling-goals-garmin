# Cycling Goals for Garmin

A Garmin Edge Connect IQ data field that answers one question during a ride: **how much distance remains for today?**

## Distance-only MVP

The rider configures yearly, monthly, and weekly distance goals in the field's on-device settings. The field uses cycling activity history and the current ride's elapsed distance to calculate today's target automatically. A rider may set a temporary override for today; it expires when the date changes.

The automatic target for today is the largest of the daily averages required to finish the yearly, monthly, and weekly goals.

On Sunday, the default includes all distance still required to close the weekly goal. If Sunday falls within the final five calendar days of the month, it also includes all distance required to close the monthly goal. Because a ride counts toward both periods, the larger remainder is used rather than adding them.

Completed rides earlier today and the current ride are subtracted from today's target. The displayed value never falls below zero.

Elevation goals are intentionally paused because Connect IQ's activity-history records expose distance but not historical elevation gain.

## Current interface

```text
REMAINING FOR TODAY

0.0

MILES or KM
```

If goals are missing, the data field directs the rider to its standard Settings screen. The settings use a native touch menu for Daily, Weekly, Monthly, and Yearly. Daily is automatic unless the rider creates a same-day override. Weekly, monthly, and yearly values persist.

All distances are stored internally in meters. Display and editing follow the unit system selected in Garmin's device settings.

## Scenario tests

The source includes Garmin simulator unit tests for the agreed scenarios:

- S1: Saturday, 157.3 miles completed before a 24-mile active ride → 4.85 miles remaining today
- S2: Sunday, 20 weekly miles and 999 monthly miles completed → 195 miles remaining today
- S3: Monday's 100-mile ride → 0 miles remaining today when no longer-period requirement exceeds it
- Month-end Sunday uses the larger weekly or monthly remainder rather than adding them

## Supported devices and prerequisites

- Edge 840 / 840 Solar
- Edge 1040 / 1040 Solar
- Edge 1050
- Connect IQ API 5.2.2 or newer
- Garmin Connect IQ SDK and a developer key for local builds

This is an early MVP implementation. It has not yet been compiled because the Garmin Connect IQ SDK is not installed in the development environment.
