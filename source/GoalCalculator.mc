using Toybox.Activity;
using Toybox.Gregorian;
using Toybox.Math;
using Toybox.Time;
using Toybox.UserProfile;

class GoalCalculator {
    static function remainingForToday(info as Activity.Info) as Float {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var goals = GoalStore.getGoals();
        var totals = historyBeforeAndToday(today);
        var override = GoalStore.getDailyOverride(dateKey(today));

        var suggested = override == null
            ? calculateAutomaticGoal(
                goals[0], totals[0], daysRemainingInYear(today),
                goals[1], totals[1], daysRemainingInMonth(today),
                goals[2], totals[2], daysRemainingInWeek(today),
                today.day_of_week == 1, daysRemainingInMonth(today) <= 5)
            : override.toFloat();

        var currentRide = info.elapsedDistance == null ? 0.0 : info.elapsedDistance.toFloat();
        return remainingAfterProgress(suggested, totals[3], currentRide);
    }

    static function calculateAutomaticGoal(
        yearGoal as Numeric, yearBeforeToday as Numeric, yearDays as Number,
        monthGoal as Numeric, monthBeforeToday as Numeric, monthDays as Number,
        weekGoal as Numeric, weekBeforeToday as Numeric, weekDays as Number,
        isSunday as Boolean, isMonthEndWindow as Boolean) as Float {

        var yearDaily = remaining(yearGoal, yearBeforeToday) / yearDays;
        var monthDaily = remaining(monthGoal, monthBeforeToday) / monthDays;
        var weekDaily = remaining(weekGoal, weekBeforeToday) / weekDays;
        var suggested = Math.max(yearDaily, Math.max(monthDaily, weekDaily));

        if (isSunday) {
            suggested = Math.max(suggested, remaining(weekGoal, weekBeforeToday));
            if (isMonthEndWindow) {
                suggested = Math.max(suggested, remaining(monthGoal, monthBeforeToday));
            }
        }
        return suggested;
    }

    static function remainingAfterProgress(target as Numeric, completedToday as Numeric,
            currentRide as Numeric) as Float {
        return Math.max(0.0, target.toFloat() - completedToday.toFloat() - currentRide.toFloat());
    }

    // Meters before today for year/month/week, followed by meters completed today.
    private static function historyBeforeAndToday(today as Gregorian.Info) as Array<Float> {
        var totals = [0.0, 0.0, 0.0, 0.0];
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
                        if (daysBetween(date, today) <= daysSinceMonday(today)) { totals[2] += meters; }
                    }
                }
            }
            item = iterator.next();
        }
        return totals;
    }

    private static function remaining(goal as Numeric, completed as Numeric) as Float {
        return Math.max(0.0, goal.toFloat() - completed.toFloat());
    }
    private static function dateKey(date as Gregorian.Info) as Number {
        return (date.year * 10000) + (date.month * 100) + date.day;
    }
    private static function sameDate(a as Gregorian.Info, b as Gregorian.Info) as Boolean {
        return a.year == b.year && a.month == b.month && a.day == b.day;
    }
    private static function daysBetween(a as Gregorian.Info, b as Gregorian.Info) as Number {
        var am = Gregorian.moment({:year=>a.year, :month=>a.month, :day=>a.day});
        var bm = Gregorian.moment({:year=>b.year, :month=>b.month, :day=>b.day});
        return ((bm.value() - am.value()) / 86400).toNumber();
    }
    private static function daysSinceMonday(today as Gregorian.Info) as Number {
        return today.day_of_week == 1 ? 6 : today.day_of_week - 2;
    }
    private static function daysRemainingInWeek(today as Gregorian.Info) as Number {
        return today.day_of_week == 1 ? 1 : 9 - today.day_of_week;
    }
    private static function daysRemainingInMonth(today as Gregorian.Info) as Number {
        return daysInMonth(today.year, today.month) - today.day + 1;
    }
    private static function daysRemainingInYear(today as Gregorian.Info) as Number {
        var total = 0;
        for (var month = today.month; month <= 12; month += 1) { total += daysInMonth(today.year, month); }
        return total - today.day + 1;
    }
    private static function daysInMonth(year as Number, month as Number) as Number {
        if (month == 2) {
            var leap = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
            return leap ? 29 : 28;
        }
        return (month == 4 || month == 6 || month == 9 || month == 11) ? 30 : 31;
    }
}
