using Toybox.Activity;
using Toybox.Gregorian;
using Toybox.Math;
using Toybox.Time;
using Toybox.UserProfile;

class GoalCalculator {
    const METERS_PER_MILE = 1609.344;

    static function remainingForToday(info as Activity.Info) as Float {
        var goals = GoalStore.getGoals();
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var totals = historyBeforeAndToday(today);
        var yearDaily = remaining(goals[0], totals[0]) / daysRemainingInYear(today);
        var monthDaily = remaining(goals[1], totals[1]) / daysRemainingInMonth(today);
        var weekDaily = remaining(goals[2], totals[2]) / daysRemainingInWeek(today);
        var suggested = Math.max(goals[3].toFloat(), Math.max(yearDaily, Math.max(monthDaily, weekDaily)));

        // Gregorian Sunday is 1: close the week today.
        if (today.day_of_week == 1) {
            suggested = Math.max(suggested, remaining(goals[2], totals[2]));
            // If month-end is within five days, use Sunday to close the month too.
            if (daysRemainingInMonth(today) <= 5) {
                suggested = Math.max(suggested, remaining(goals[1], totals[1]));
            }
        }

        var currentRide = info.elapsedDistance == null ? 0.0 : info.elapsedDistance.toFloat() / METERS_PER_MILE;
        return Math.max(0.0, suggested - totals[3] - currentRide);
    }

    // Miles before today for year/month/week, followed by miles completed today.
    private static function historyBeforeAndToday(today as Gregorian.Info) as Array<Float> {
        var totals = [0.0, 0.0, 0.0, 0.0];
        var iterator = UserProfile.getUserActivityHistory();
        var item = iterator.next();
        while (item != null) {
            if (item.startTime != null && item.distance != null && item.type == Activity.SPORT_CYCLING) {
                var date = Gregorian.info(item.startTime, Time.FORMAT_SHORT);
                if (date.year < today.year) { break; }
                var miles = item.distance.toFloat() / METERS_PER_MILE;
                if (sameDate(date, today)) {
                    totals[3] += miles;
                } else {
                    totals[0] += miles;
                    if (date.month == today.month) { totals[1] += miles; }
                    if (daysBetween(date, today) <= daysSinceMonday(today)) { totals[2] += miles; }
                }
            }
            item = iterator.next();
        }
        return totals;
    }

    private static function remaining(goal as Number, completed as Float) as Float {
        return Math.max(0.0, goal.toFloat() - completed);
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
