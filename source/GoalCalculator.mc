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

    // Required remaining, required target, completed today, original automatic target
    // (meters), and 1.0 when a weekday limit is active.
    static function distanceStateForToday(info as Activity.Info) as Lang.Array<Lang.Float> {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var goals = GoalStore.getGoals();
        var totals = historyBeforeAndToday(today);
        var override = GoalStore.getDailyOverride(dateKey(today));
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;

        var automaticState = calculateScheduledAutomaticGoal(
                goals[0], totals[0], daysRemainingInYear(today),
                goals[1], totals[1], daysRemainingInMonth(today),
                goals[2], totals[2], daysRemainingInConfiguredWeek(todayNumber, firstDay),
                isLastDayOfConfiguredWeek(todayNumber, firstDay), daysRemainingInMonth(today) <= 5,
                todayNumber, GoalStore.getRestWeekdays(), GoalStore.getLongDays(),
                GoalStore.getLongDayDistanceGoal(), totals[4].toNumber(),
                GoalStore.getWeekdayDistanceLimit());
        var automatic = automaticState[0];
        var suggested = override == null ? automatic : override.toFloat();
        var limitApplied = override == null ? automaticState[1] : 0.0;

        var currentRide = info.elapsedDistance == null ? 0.0 : info.elapsedDistance.toFloat();
        var completedToday = totals[3] + currentRide;
        return [remainingAfterProgress(suggested, totals[3], currentRide), suggested,
            completedToday, automatic, limitApplied, automaticState[2]];
    }

    static function remainingElevationForToday(info as Activity.Info) as Lang.Float {
        var distanceState = distanceStateForToday(info);
        return elevationStateForToday(info, distanceState[5] > 0)[0];
    }

    // Remaining elevation, today's elevation target (meters), and 1.0 when a
    // weekday limit is active.
    static function elevationStateForToday(info as Activity.Info,
            weekdayAvailable as Lang.Boolean) as Lang.Array<Lang.Float> {
        var currentAscent = info.totalAscent == null ? 0.0 : info.totalAscent.toFloat();
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var targetState = scheduledElevationTarget(GoalStore.getDailyElevationGoal(),
            today.day_of_week as Lang.Number, GoalStore.getRestWeekdays(),
            GoalStore.getLongDays(), GoalStore.getLongDayElevationGoal(),
            GoalStore.getWeekdayElevationLimit());
        if (!weekdayAvailable && isWeekday(today.day_of_week as Lang.Number)) {
            targetState = [0.0, 0.0];
        }
        return [remainingAfterProgress(targetState[0], 0.0, currentAscent),
            targetState[0], targetState[1]];
    }

    static function calculateScheduledAutomaticGoal(
        yearGoal as Lang.Numeric, yearBeforeToday as Lang.Numeric, yearDays as Lang.Number,
        monthGoal as Lang.Numeric, monthBeforeToday as Lang.Numeric, monthDays as Lang.Number,
        weekGoal as Lang.Numeric, weekBeforeToday as Lang.Numeric, weekDays as Lang.Number,
        isLastDayOfWeek as Lang.Boolean, isMonthEndWindow as Lang.Boolean,
        todayNumber as Lang.Number, restWeekdays as Lang.Number, longDays as Lang.Number,
        longDayDistance as Lang.Numeric, usedWeekdayRideDays as Lang.Number,
        weekdayLimit as Lang.Numeric or Null
    ) as Lang.Array<Lang.Float> {
        var isWeekdayToday = isWeekday(todayNumber);
        var isLongDayToday = isLongDay(todayNumber, longDays);
        var yearCounts = scheduleCounts(todayNumber, yearDays, restWeekdays,
            longDays, usedWeekdayRideDays);
        var monthCounts = scheduleCounts(todayNumber, monthDays, restWeekdays,
            longDays, usedWeekdayRideDays);
        var weekCounts = scheduleCounts(todayNumber, weekDays, restWeekdays,
            longDays, usedWeekdayRideDays);
        var yearState = scheduledPeriodTarget(remaining(yearGoal, yearBeforeToday),
            yearCounts, isWeekdayToday, isLongDayToday, longDayDistance, weekdayLimit);
        var monthState = scheduledPeriodTarget(remaining(monthGoal, monthBeforeToday),
            monthCounts, isWeekdayToday, isLongDayToday, longDayDistance, weekdayLimit);
        var weekState = scheduledPeriodTarget(remaining(weekGoal, weekBeforeToday),
            weekCounts, isWeekdayToday, isLongDayToday, longDayDistance, weekdayLimit);

        if (isLastDayOfWeek) {
            weekState = applyWeekdayLimit(remaining(weekGoal, weekBeforeToday),
                isWeekdayToday, weekdayLimit);
            if (isMonthEndWindow) {
                monthState = applyWeekdayLimit(remaining(monthGoal, monthBeforeToday),
                    isWeekdayToday, weekdayLimit);
            }
        }
        var availableToday = !isWeekdayToday
            || usedWeekdayRideDays < maximumNumber(0, 5 - restWeekdays);
        if (!availableToday) {
            yearState = [0.0, 0.0];
            monthState = [0.0, 0.0];
            weekState = [0.0, 0.0];
        }
        var suggested = maximum(yearState[0], maximum(monthState[0], weekState[0]));
        var limited = yearState[1] > 0 || monthState[1] > 0 || weekState[1] > 0;
        return [suggested, limited ? 1.0 : 0.0, availableToday ? 1.0 : 0.0];
    }

    // Available ordinary weekday slots, ordinary weekend slots, and long-day slots.
    static function scheduleCounts(startDay as Lang.Number, days as Lang.Number,
            restWeekdays as Lang.Number, longDays as Lang.Number,
            usedWeekdayRideDays as Lang.Number) as Lang.Array<Lang.Number> {
        var boundedRest = restWeekdays < 0 ? 0 : (restWeekdays > 5 ? 5 : restWeekdays);
        var boundedLong = longDays < 0 ? 0 : (longDays > 2 ? 2 : longDays);
        var firstLength = minimumNumber(days,
            ((Gregorian.DAY_SUNDAY - startDay + 7) % 7) + 1);
        var firstWeekdays = countWeekdays(startDay, firstLength);
        var firstAllowance = maximumNumber(0, 5 - boundedRest - usedWeekdayRideDays);
        var weekdaySlots = minimumNumber(firstWeekdays, firstAllowance);
        var remainingDays = days - firstLength;
        var fullWeeks = (remainingDays / 7).toNumber();
        weekdaySlots += fullWeeks * (5 - boundedRest);
        var tailDays = remainingDays - (fullWeeks * 7);
        weekdaySlots += minimumNumber(countWeekdays(Gregorian.DAY_MONDAY, tailDays),
            5 - boundedRest);

        var saturdays = countDay(startDay, days, Gregorian.DAY_SATURDAY);
        var sundays = countDay(startDay, days, Gregorian.DAY_SUNDAY);
        var longSlots = boundedLong >= 1 ? saturdays : 0;
        if (boundedLong >= 2) { longSlots += sundays; }
        var ordinaryWeekendSlots = saturdays + sundays - longSlots;
        return [weekdaySlots, ordinaryWeekendSlots, longSlots];
    }

    // Returns today's target followed by a numeric weekday-limit flag.
    static function scheduledPeriodTarget(remainingGoal as Lang.Numeric,
            counts as Lang.Array<Lang.Number>, isWeekdayToday as Lang.Boolean,
            isLongDayToday as Lang.Boolean,
            longDayDistance as Lang.Numeric,
            weekdayLimit as Lang.Numeric or Null) as Lang.Array<Lang.Float> {
        var weekdaySlots = counts[0];
        var ordinaryWeekendSlots = counts[1];
        var longSlots = counts[2];
        var regularSlots = weekdaySlots + ordinaryWeekendSlots;
        var goal = remainingGoal.toFloat();
        var regularTarget = 0.0;
        var longTarget = 0.0;

        if (regularSlots > 0) {
            regularTarget = maximum(0.0,
                goal - (longSlots * longDayDistance.toFloat())) / regularSlots;
            if (regularTarget > longDayDistance) {
                regularTarget = goal / (regularSlots + longSlots);
            }
        }
        if (longSlots > 0) {
            longTarget = maximum(longDayDistance,
                regularSlots == 0 ? goal / longSlots : regularTarget);
        }

        var limited = weekdayLimit != null && regularTarget > weekdayLimit.toFloat();
        if (limited) {
            var cappedWeekdayContribution = weekdaySlots * weekdayLimit.toFloat();
            var weekendGoal = maximum(0.0, goal - cappedWeekdayContribution);
            if (ordinaryWeekendSlots > 0) {
                regularTarget = maximum(0.0,
                    weekendGoal - (longSlots * longDayDistance.toFloat()))
                    / ordinaryWeekendSlots;
                if (regularTarget > longDayDistance) {
                    regularTarget = weekendGoal / (ordinaryWeekendSlots + longSlots);
                }
            } else {
                regularTarget = 0.0;
            }
            if (longSlots > 0) {
                longTarget = maximum(longDayDistance,
                    ordinaryWeekendSlots == 0 ? weekendGoal / longSlots : regularTarget);
            }
        }

        if (isWeekdayToday) {
            if (weekdaySlots <= 0) { return [0.0, 0.0]; }
            return [limited ? weekdayLimit.toFloat() : regularTarget,
                limited ? 1.0 : 0.0];
        }
        return [isLongDayToday ? longTarget : regularTarget, 0.0];
    }

    static function scheduledElevationTarget(baseTarget as Lang.Numeric,
            todayNumber as Lang.Number, restWeekdays as Lang.Number,
            longDays as Lang.Number, longDayElevation as Lang.Numeric,
            weekdayLimit as Lang.Numeric or Null
    ) as Lang.Array<Lang.Float> {
        if (isLongDay(todayNumber, longDays)) {
            return [longDayElevation.toFloat(), 0.0];
        }
        if (!isWeekday(todayNumber)) { return [baseTarget.toFloat(), 0.0]; }
        var rideWeekdays = 5 - restWeekdays;
        if (rideWeekdays <= 0) { return [0.0, 0.0]; }
        var target = baseTarget.toFloat() * 5 / rideWeekdays;
        return applyWeekdayLimit(target, true, weekdayLimit);
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

    // Meters before today for year/month/week, meters completed today, then the
    // number of distinct weekday ride days already used in the current calendar week.
    private static function historyBeforeAndToday(today as Gregorian.Info) as Lang.Array<Lang.Float> {
        var totals = [0.0, 0.0, 0.0, 0.0, 0.0];
        var usedWeekdayDates = [];
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;
        var daysSinceWeekStart = daysSinceConfiguredWeekStart(todayNumber, firstDay);
        var daysSinceMonday = daysSinceConfiguredWeekStart(todayNumber, Gregorian.DAY_MONDAY);
        var iterator = UserProfile.getUserActivityHistory();
        var item = iterator.next();
        while (item != null) {
            if (item.startTime != null && item.distance != null && item.type == Activity.SPORT_CYCLING) {
                var date = Gregorian.info(item.startTime, Time.FORMAT_SHORT);
                var age = daysBetween(date, today);
                if (age > 0 && age <= daysSinceMonday && isWeekday(date.day_of_week as Lang.Number)
                        && item.distance > 0) {
                    var key = dateKey(date);
                    if (!containsNumber(usedWeekdayDates, key)) { usedWeekdayDates.add(key); }
                }
                // Do not rely on the iterator returning newest activities first.
                var meters = item.distance.toFloat();
                if (sameDate(date, today)) {
                    totals[3] += meters;
                } else if (age > 0) {
                    if (date.year == today.year) {
                        totals[0] += meters;
                        if (date.month == today.month) { totals[1] += meters; }
                    }
                    // A configured week can cross a month or year boundary.
                    if (age <= daysSinceWeekStart) { totals[2] += meters; }
                }
            }
            item = iterator.next();
        }
        totals[4] = usedWeekdayDates.size().toFloat();
        return totals;
    }

    private static function applyWeekdayLimit(target as Lang.Numeric,
            isWeekdayToday as Lang.Boolean, weekdayLimit as Lang.Numeric or Null
    ) as Lang.Array<Lang.Float> {
        if (isWeekdayToday && weekdayLimit != null && target > weekdayLimit) {
            return [weekdayLimit.toFloat(), 1.0];
        }
        return [target.toFloat(), 0.0];
    }

    private static function isWeekday(day as Lang.Number) as Lang.Boolean {
        return day != Gregorian.DAY_SATURDAY && day != Gregorian.DAY_SUNDAY;
    }

    private static function isLongDay(day as Lang.Number, longDays as Lang.Number) as Lang.Boolean {
        return (longDays >= 1 && day == Gregorian.DAY_SATURDAY)
            || (longDays >= 2 && day == Gregorian.DAY_SUNDAY);
    }

    private static function countWeekdays(startDay as Lang.Number, days as Lang.Number) as Lang.Number {
        var total = 0;
        for (var day = Gregorian.DAY_MONDAY; day <= Gregorian.DAY_FRIDAY; day += 1) {
            total += countDay(startDay, days, day);
        }
        return total;
    }

    private static function countDay(startDay as Lang.Number, days as Lang.Number,
            requestedDay as Lang.Number) as Lang.Number {
        if (days <= 0) { return 0; }
        var offset = (requestedDay - startDay + 7) % 7;
        if (offset >= days) { return 0; }
        return 1 + (((days - 1 - offset) / 7).toNumber());
    }

    private static function containsNumber(values as Lang.Array, value as Lang.Number) as Lang.Boolean {
        for (var i = 0; i < values.size(); i += 1) {
            if (values[i] == value) { return true; }
        }
        return false;
    }

    private static function remaining(goal as Lang.Numeric, completed as Lang.Numeric) as Lang.Float {
        return maximum(0.0, goal.toFloat() - completed.toFloat());
    }
    private static function maximum(a as Lang.Numeric, b as Lang.Numeric) as Lang.Float {
        return a > b ? a.toFloat() : b.toFloat();
    }
    private static function minimumNumber(a as Lang.Number, b as Lang.Number) as Lang.Number {
        return a < b ? a : b;
    }
    private static function maximumNumber(a as Lang.Number, b as Lang.Number) as Lang.Number {
        return a > b ? a : b;
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
