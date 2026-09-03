# Cycling Goals for Garmin

A Garmin Edge Connect IQ data field that shows how much distance and climbing remain for today's ride.

## Current MVP

The rider configures yearly, monthly, and weekly distance goals in the field's on-device settings. The field uses cycling activity history and the current ride's elapsed distance to calculate today's target automatically. A rider may set a temporary override for today; it expires when the date changes.

The automatic target for today is the largest of the daily averages required to finish the yearly, monthly, and weekly goals.

On Sunday, the default includes all distance still required to close the weekly goal. If Sunday falls within the final five calendar days of the month, it also includes all distance required to close the monthly goal. Because a ride counts toward both periods, the larger remainder is used rather than adding them.

Completed rides earlier today and the current ride are subtracted from today's target. The displayed value never falls below zero.

The rider can also set a daily elevation goal. It defaults to 1,370 feet and is reduced only by the current ride's live total ascent. Historical climbing is intentionally excluded because Connect IQ's activity-history records expose distance but not elevation gain.

On supported color devices, each half communicates its own progress: red below 75% complete, black from 75% through 99.9%, and green when the goal is met. Distance and elevation change color independently.

The display also estimates the time needed to complete the remaining distance. It uses the ride average until five miles of data are available, then uses a rolling average of the most recent five miles. Paused time is excluded. The estimate appears in a neutral black center section in `00H:00M` format.

## Current interface

```text
REMAINING FOR TODAY

0.0

MILES or KM

----------------

1370

FT or M
```

If goals are missing, the data field directs the rider to its standard Settings screen. The settings use a native touch menu for Daily Distance, Daily Elevation, Weekly, Monthly, and Yearly. Daily distance is automatic unless the rider creates a same-day override. The daily elevation goal and weekly, monthly, and yearly distance goals persist.

First-time defaults are 100 miles weekly, 500 miles monthly, and 7,000 miles yearly. They are converted for display when the device uses metric units. Goal editing uses Garmin's native picker so values redraw reliably and inherit the device's standard touch behavior.

Distances and elevations are stored internally in meters. Display and editing follow the distance and elevation units selected in Garmin's device settings.

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

The prototype compiles successfully with Connect IQ SDK 9.2.0 for all three supported Edge targets. Its four distance-calculation scenarios pass in Garmin's Edge 840 simulator.
