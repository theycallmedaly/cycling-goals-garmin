using Toybox.Activity;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

class GoalCalculator {
    // Builds the named distance state consumed by the ride view.
    static function distanceStateForToday(info as Activity.Info) as DistanceGoalState {
        var today = Gregorian.info(GoalRuntime.now(), Time.FORMAT_SHORT);
        var goals = GoalStore.getGoals();
        var totals = historyBeforeAndToday(today);
        var override = GoalStore.getDailyOverride(dateKey(today));
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;

        var automaticState = calculateScheduledAutomaticGoal(
                goals.yearlyMeters, totals.yearBeforeTodayMeters, daysRemainingInYear(today),
                goals.monthlyMeters, totals.monthBeforeTodayMeters, daysRemainingInMonth(today),
                goals.weeklyMeters, totals.weekBeforeTodayMeters,
                daysRemainingInConfiguredWeek(todayNumber, firstDay),
                isLastDayOfConfiguredWeek(todayNumber, firstDay), daysRemainingInMonth(today) <= 5,
                todayNumber, GoalStore.getRestWeekdays(), GoalStore.getLongDays(),
                GoalStore.getLongDayDistanceGoal(), totals.usedWeekdayRideDays,
                GoalStore.getWeekdayDistanceLimit());
        var automatic = automaticState.targetMeters;
        var suggested = override == null ? automatic : override.toFloat();
        var limitApplied = override == null && automaticState.weekdayLimitApplied;

        var currentRide = info.elapsedDistance == null ? 0.0 : info.elapsedDistance.toFloat();
        var completedToday = totals.completedTodayMeters + currentRide;
        return new DistanceGoalState(
            remainingAfterProgress(suggested, totals.completedTodayMeters, currentRide), suggested,
            completedToday, automatic, limitApplied, automaticState.availableToday);
    }

    // Builds the named elevation state consumed by the ride view.
    static function elevationStateForToday(info as Activity.Info,
            weekdayAvailable as Lang.Boolean) as ElevationGoalState {
        var currentAscent = info.totalAscent == null ? 0.0 : info.totalAscent.toFloat();
        var today = Gregorian.info(GoalRuntime.now(), Time.FORMAT_SHORT);
        var targetState = scheduledElevationTarget(GoalStore.getDailyElevationGoal(),
            today.day_of_week as Lang.Number, GoalStore.getRestWeekdays(),
            GoalStore.getLongDays(), GoalStore.getLongDayElevationGoal(),
            GoalStore.getWeekdayElevationLimit());
        if (!weekdayAvailable && isWeekday(today.day_of_week as Lang.Number)) {
            targetState = new ScheduledTarget(0.0, false);
        }
        return new ElevationGoalState(
            remainingAfterProgress(targetState.targetMeters, 0.0, currentAscent),
            targetState.targetMeters, targetState.weekdayLimitApplied);
    }

    static function calculateScheduledAutomaticGoal(
        yearGoal as Lang.Numeric, yearBeforeToday as Lang.Numeric, yearDays as Lang.Number,
        monthGoal as Lang.Numeric, monthBeforeToday as Lang.Numeric, monthDays as Lang.Number,
        weekGoal as Lang.Numeric, weekBeforeToday as Lang.Numeric, weekDays as Lang.Number,
        isLastDayOfWeek as Lang.Boolean, isMonthEndWindow as Lang.Boolean,
        todayNumber as Lang.Number, restWeekdays as Lang.Number, longDays as Lang.Number,
        longDayDistance as Lang.Numeric, usedWeekdayRideDays as Lang.Number,
        weekdayLimit as Lang.Numeric or Null
    ) as ScheduledAutomaticTarget {
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
            yearState = new ScheduledTarget(0.0, false);
            monthState = new ScheduledTarget(0.0, false);
            weekState = new ScheduledTarget(0.0, false);
        }
        var suggested = maximum(yearState.targetMeters,
            maximum(monthState.targetMeters, weekState.targetMeters));
        var limited = yearState.weekdayLimitApplied || monthState.weekdayLimitApplied
            || weekState.weekdayLimitApplied;
        return new ScheduledAutomaticTarget(suggested, limited, availableToday);
    }

    // Available ordinary weekday slots, ordinary weekend slots, and long-day slots.
    static function scheduleCounts(startDay as Lang.Number, days as Lang.Number,
            restWeekdays as Lang.Number, longDays as Lang.Number,
            usedWeekdayRideDays as Lang.Number) as ScheduleCounts {
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
        return new ScheduleCounts(weekdaySlots, ordinaryWeekendSlots, longSlots);
    }

    // Returns today's target and whether the weekday limit supplied that target.
    static function scheduledPeriodTarget(remainingGoal as Lang.Numeric,
            counts as ScheduleCounts, isWeekdayToday as Lang.Boolean,
            isLongDayToday as Lang.Boolean,
            longDayDistance as Lang.Numeric,
            weekdayLimit as Lang.Numeric or Null) as ScheduledTarget {
        var weekdaySlots = counts.weekdaySlots;
        var ordinaryWeekendSlots = counts.ordinaryWeekendSlots;
        var longSlots = counts.longDaySlots;
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
            if (weekdaySlots <= 0) { return new ScheduledTarget(0.0, false); }
            return new ScheduledTarget(
                limited ? weekdayLimit.toFloat() : regularTarget, limited);
        }
        return new ScheduledTarget(isLongDayToday ? longTarget : regularTarget, false);
    }

    static function scheduledElevationTarget(baseTarget as Lang.Numeric,
            todayNumber as Lang.Number, restWeekdays as Lang.Number,
            longDays as Lang.Number, longDayElevation as Lang.Numeric,
            weekdayLimit as Lang.Numeric or Null
    ) as ScheduledTarget {
        if (isLongDay(todayNumber, longDays)) {
            return new ScheduledTarget(longDayElevation, false);
        }
        if (!isWeekday(todayNumber)) { return new ScheduledTarget(baseTarget, false); }
        var rideWeekdays = 5 - restWeekdays;
        if (rideWeekdays <= 0) { return new ScheduledTarget(0.0, false); }
        var target = baseTarget.toFloat() * 5 / rideWeekdays;
        return applyWeekdayLimit(target, true, weekdayLimit);
    }

    static function remainingAfterProgress(target as Lang.Numeric, completedToday as Lang.Numeric,
            currentRide as Lang.Numeric) as Lang.Float {
        return maximum(0.0, target.toFloat() - completedToday.toFloat() - currentRide.toFloat());
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

    // Collects named period totals and the distinct weekday ride days already
    // used in the current calendar week.
    private static function historyBeforeAndToday(today as Gregorian.Info) as HistoryTotals {
        var totals = new HistoryTotals();
        var usedWeekdayDates = [];
        var firstDay = System.getDeviceSettings().firstDayOfWeek;
        var todayNumber = today.day_of_week as Lang.Number;
        var daysSinceWeekStart = daysSinceConfiguredWeekStart(todayNumber, firstDay);
        var daysSinceMonday = daysSinceConfiguredWeekStart(todayNumber, Gregorian.DAY_MONDAY);
        var iterator = GoalRuntime.activityHistoryIterator();
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
                    totals.completedTodayMeters += meters;
                } else if (age > 0) {
                    if (date.year == today.year) {
                        totals.yearBeforeTodayMeters += meters;
                        if (date.month == today.month) {
                            totals.monthBeforeTodayMeters += meters;
                        }
                    }
                    // A configured week can cross a month or year boundary.
                    if (age <= daysSinceWeekStart) {
                        totals.weekBeforeTodayMeters += meters;
                    }
                }
            }
            item = iterator.next();
        }
        totals.usedWeekdayRideDays = usedWeekdayDates.size();
        return totals;
    }

    private static function applyWeekdayLimit(target as Lang.Numeric,
            isWeekdayToday as Lang.Boolean, weekdayLimit as Lang.Numeric or Null
    ) as ScheduledTarget {
        if (isWeekdayToday && weekdayLimit != null && target > weekdayLimit) {
            return new ScheduledTarget(weekdayLimit, true);
        }
        return new ScheduledTarget(target, false);
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
