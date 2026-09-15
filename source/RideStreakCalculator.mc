using Toybox.Activity;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;

class RideStreakCalculator {
    static function count(activeRideToday as Lang.Boolean) as Lang.Number {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return countFrom(UserProfile.getUserActivityHistory(), today, activeRideToday);
    }

    static function countFrom(iterator, today as Gregorian.Info,
            activeRideToday as Lang.Boolean) as Lang.Number {
        var riddenAges = [];
        var item = iterator.next();
        while (item != null) {
            if (item.startTime != null && item.type == Activity.SPORT_CYCLING) {
                var date = Gregorian.info(item.startTime, Time.FORMAT_SHORT);
                var age = daysBetween(date, today);
                if (age >= 0 && !containsAge(riddenAges, age)) {
                    riddenAges.add(age);
                }
            }
            item = iterator.next();
        }

        if (activeRideToday && !containsAge(riddenAges, 0)) {
            riddenAges.add(0);
        }

        // Before today's first ride, today is not a missed day: continue the
        // streak ending yesterday. Once today is ridden, include it.
        var age = containsAge(riddenAges, 0) ? 0 : 1;
        var streak = 0;
        while (containsAge(riddenAges, age)) {
            streak += 1;
            age += 1;
        }
        return streak;
    }

    static function shouldDisplay(rideStarted as Lang.Boolean,
            etaTrendState as Lang.Symbol, streak as Lang.Number) as Lang.Boolean {
        if (!rideStarted) { return true; }
        return etaTrendState == :measuring && streak >= 2;
    }

    private static function containsAge(ages as Lang.Array,
            requested as Lang.Number) as Lang.Boolean {
        for (var i = 0; i < ages.size(); i += 1) {
            if (ages[i] == requested) { return true; }
        }
        return false;
    }

    private static function daysBetween(a as Gregorian.Info,
            b as Gregorian.Info) as Lang.Number {
        var am = Gregorian.moment({:year=>a.year, :month=>a.month, :day=>a.day});
        var bm = Gregorian.moment({:year=>b.year, :month=>b.month, :day=>b.day});
        return ((bm.value() - am.value()) / 86400).toNumber();
    }
}
