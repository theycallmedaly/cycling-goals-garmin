using Toybox.Activity;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

class GoalCalculator {
    static function remainingForToday(info as Activity.Info) as Lang.Float {
        return distanceStateForToday(info)[0];
    }

    // Required remaining, required target, completed today, and original automatic target (meters).
    static function distanceStateForToday(info as Activity.Info) as Lang.Array<Lang.Float> {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var goals = GoalStore.getGoals();
        var totals = historyBeforeAndToday(today);
        var override = GoalStore.getDailyOverride(dateKey(today));
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;

        var automatic = calculateAutomaticGoal(
                goals[0], totals[0], daysRemainingInYear(today),
                goals[1], totals[1], daysRemainingInMonth(today),
                goals[2], totals[2], daysRemainingInConfiguredWeek(todayNumber, firstDay),
                isLastDayOfConfiguredWeek(todayNumber, firstDay), daysRemainingInMonth(today) <= 5);
        var suggested = override == null ? automatic : override.toFloat();

        var currentRide = info.elapsedDistance == null ? 0.0 : info.elapsedDistance.toFloat();
        var completedToday = totals[3] + currentRide;
        return [remainingAfterProgress(suggested, totals[3], currentRide), suggested,
            completedToday, automatic];
    }

    static function remainingElevationForToday(info as Activity.Info) as Lang.Float {
        return elevationStateForToday(info)[0];
    }

    // Remaining elevation followed by today's elevation target, both in meters.
    static function elevationStateForToday(info as Activity.Info) as Lang.Array<Lang.Float> {
        var currentAscent = info.totalAscent == null ? 0.0 : info.totalAscent.toFloat();
        var target = GoalStore.getDailyElevationGoal().toFloat();
        return [remainingAfterProgress(target, 0.0, currentAscent), target];
    }

    static function calculateAutomaticGoal(
        yearGoal as Lang.Numeric, yearBeforeToday as Lang.Numeric, yearDays as Lang.Number,
        monthGoal as Lang.Numeric, monthBeforeToday as Lang.Numeric, monthDays as Lang.Number,
        weekGoal as Lang.Numeric, weekBeforeToday as Lang.Numeric, weekDays as Lang.Number,
        isLastDayOfWeek as Lang.Boolean, isMonthEndWindow as Lang.Boolean) as Lang.Float {

        var yearDaily = remaining(yearGoal, yearBeforeToday) / yearDays;
        var monthDaily = remaining(monthGoal, monthBeforeToday) / monthDays;
        var weekDaily = remaining(weekGoal, weekBeforeToday) / weekDays;
        var suggested = maximum(yearDaily, maximum(monthDaily, weekDaily));

        if (isLastDayOfWeek) {
            suggested = maximum(suggested, remaining(weekGoal, weekBeforeToday));
            if (isMonthEndWindow) {
                suggested = maximum(suggested, remaining(monthGoal, monthBeforeToday));
            }
        }
        return suggested;
    }

    static function remainingAfterProgress(target as Lang.Numeric, completedToday as Lang.Numeric,
            currentRide as Lang.Numeric) as Lang.Float {
        return maximum(0.0, target.toFloat() - completedToday.toFloat() - currentRide.toFloat());
    }

    static function crossedHalfway(previousFraction as Lang.Numeric, remaining as Lang.Numeric,
            target as Lang.Numeric) as Lang.Boolean {
        if (target <= 0 || previousFraction >= 0.5) { return false; }
        var currentFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        // Garmin may not run a data field until its screen becomes active. Treat the
        // first reading as a transition from the start of the ride so a milestone
        // already crossed while another data screen was visible is not discarded.
        return currentFraction >= 0.5;
    }

    static function crossedGoal(previousFraction as Lang.Numeric, remaining as Lang.Numeric,
            target as Lang.Numeric) as Lang.Boolean {
        if (target <= 0 || previousFraction >= 1.0) { return false; }
        var currentFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        return currentFraction >= 1.0;
    }

    static function daysSinceConfiguredWeekStart(dayOfWeek as Lang.Number,
            firstDayOfWeek as Lang.Number) as Lang.Number {
        return (dayOfWeek - firstDayOfWeek + 7) % 7;
    }

    static function daysRemainingInConfiguredWeek(dayOfWeek as Lang.Number,
            firstDayOfWeek as Lang.Number) as Lang.Number {
        return 7 - daysSinceConfiguredWeekStart(dayOfWeek, firstDayOfWeek);
    }

    static function isLastDayOfConfiguredWeek(dayOfWeek as Lang.Number,
            firstDayOfWeek as Lang.Number) as Lang.Boolean {
        return daysRemainingInConfiguredWeek(dayOfWeek, firstDayOfWeek) == 1;
    }

    static function bonusTarget(automaticTarget as Lang.Numeric, configuredTarget as Lang.Numeric or Null) as Lang.Float {
        return configuredTarget == null ? automaticTarget.toFloat() * 0.5 : configuredTarget.toFloat();
    }

    static function elevationBonusTarget(dailyTarget as Lang.Numeric,
            configuredTarget as Lang.Numeric or Null) as Lang.Float {
        return configuredTarget == null ? dailyTarget.toFloat() : configuredTarget.toFloat();
    }

    static function bonusRemaining(requiredTarget as Lang.Numeric, completedToday as Lang.Numeric,
            bonusTargetMeters as Lang.Numeric) as Lang.Float {
        return maximum(0.0, bonusTargetMeters.toFloat() - bonusProgress(requiredTarget, completedToday));
    }

    static function bonusProgress(requiredTarget as Lang.Numeric, completedToday as Lang.Numeric) as Lang.Float {
        return maximum(0.0, completedToday.toFloat() - requiredTarget.toFloat());
    }

    static function bonusRemainingForRounds(requiredTarget as Lang.Numeric, completedToday as Lang.Numeric,
            bonusBlock as Lang.Numeric, rounds as Lang.Number) as Lang.Float {
        return maximum(0.0,
            (bonusBlock.toFloat() * rounds) - bonusProgress(requiredTarget, completedToday));
    }

    static function bonusRoundCompleted(progress as Lang.Numeric, bonusBlock as Lang.Numeric,
            acceptedRounds as Lang.Number, alertedRounds as Lang.Number) as Lang.Boolean {
        if (bonusBlock <= 0 || acceptedRounds <= alertedRounds) { return false; }
        return progress.toFloat() >= bonusBlock.toFloat() * acceptedRounds;
    }

    // Meters before today for year/month/week, followed by meters completed today.
    private static function historyBeforeAndToday(today as Gregorian.Info) as Lang.Array<Lang.Float> {
        var totals = [0.0, 0.0, 0.0, 0.0];
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;
        var daysSinceWeekStart = daysSinceConfiguredWeekStart(todayNumber, firstDay);
        var iterator = UserProfile.getUserActivityHistory();
        var item = iterator.next();
        while (item != null) {
            if (item.startTime != null && item.distance != null && item.type == Activity.SPORT_CYCLING) {
                var date = Gregorian.info(item.startTime, Time.FORMAT_SHORT);
                // Do not rely on the iterator returning newest activities first.
                if (date.year == today.year) {
                    var meters = item.distance.toFloat();
                    if (sameDate(date, today)) {
                        totals[3] += meters;
                    } else if (daysBetween(date, today) > 0) {
                        totals[0] += meters;
                        if (date.month == today.month) { totals[1] += meters; }
                        if (daysBetween(date, today) <= daysSinceWeekStart) { totals[2] += meters; }
                    }
                }
            }
            item = iterator.next();
        }
        return totals;
    }

    private static function remaining(goal as Lang.Numeric, completed as Lang.Numeric) as Lang.Float {
        return maximum(0.0, goal.toFloat() - completed.toFloat());
    }
    private static function maximum(a as Lang.Numeric, b as Lang.Numeric) as Lang.Float {
        return a > b ? a.toFloat() : b.toFloat();
    }
    private static function dateKey(date as Gregorian.Info) as Lang.Number {
        return (date.year * 10000) + (date.month * 100) + date.day;
    }
    private static function sameDate(a as Gregorian.Info, b as Gregorian.Info) as Lang.Boolean {
        return a.year == b.year && a.month == b.month && a.day == b.day;
    }
    private static function daysBetween(a as Gregorian.Info, b as Gregorian.Info) as Lang.Number {
        var am = Gregorian.moment({:year=>a.year, :month=>a.month, :day=>a.day});
        var bm = Gregorian.moment({:year=>b.year, :month=>b.month, :day=>b.day});
        return ((bm.value() - am.value()) / 86400).toNumber();
    }
    private static function daysRemainingInMonth(today as Gregorian.Info) as Lang.Number {
        return daysInMonth(today.year, today.month) - today.day + 1;
    }
    private static function daysRemainingInYear(today as Gregorian.Info) as Lang.Number {
        var total = 0;
        for (var month = today.month; month <= 12; month += 1) { total += daysInMonth(today.year, month); }
        return total - today.day + 1;
    }
    private static function daysInMonth(year as Lang.Number, month as Lang.Number) as Lang.Number {
        if (month == 2) {
            var leap = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
            return leap ? 29 : 28;
        }
        return (month == 4 || month == 6 || month == 9 || month == 11) ? 30 : 31;
    }
}
