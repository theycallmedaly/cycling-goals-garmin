using Toybox.Activity;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class StreakHistoryItem {
    var startTime as Time.Moment;
    var type as Lang.Number;

    function initialize(startTime as Time.Moment, type as Lang.Number) {
        self.startTime = startTime;
        self.type = type;
    }
}

class StreakHistoryIterator {
    private var _items as Lang.Array;
    private var _index as Lang.Number = 0;

    function initialize(items as Lang.Array) { _items = items; }

    function next() {
        if (_index >= _items.size()) { return null; }
        var item = _items[_index];
        _index += 1;
        return item;
    }
}

class RideStreakCalculatorTests {
    (:test)
    static function consecutiveRideDaysEndingYesterdayCountBeforeRide(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 13), ride(2026, 9, 12),
            ride(2026, 9, 11)], false) == 3;
    }

    (:test)
    static function multipleRidesInOneDayCountOnce(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 13), ride(2026, 9, 13),
            ride(2026, 9, 12)], false) == 2;
    }

    (:test)
    static function missingYesterdayResetsPreRideStreak(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 12), ride(2026, 9, 11)], false) == 0;
    }

    (:test)
    static function activeRideStartsNewStreakAfterMissedDay(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 12)], true) == 1;
    }

    (:test)
    static function activeRideExtendsStreakEndingYesterday(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 13), ride(2026, 9, 12),
            ride(2026, 9, 11)], true) == 4;
    }

    (:test)
    static function completedRideTodayAlreadyExtendsStreak(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 14), ride(2026, 9, 13),
            ride(2026, 9, 12)], false) == 3;
    }

    (:test)
    static function rideDistanceIsNotRequired(logger) as Lang.Boolean {
        return streak([ride(2026, 9, 13), ride(2026, 9, 12)], false) == 2;
    }

    (:test)
    static function preRideAlwaysShowsStreak(logger) as Lang.Boolean {
        return RideStreakCalculator.shouldDisplay(false, :measuring, 0);
    }

    (:test)
    static function establishedStreakShowsWhileEtaMeasures(logger) as Lang.Boolean {
        return RideStreakCalculator.shouldDisplay(true, :measuring, 2);
    }

    (:test)
    static function oneDayStreakDoesNotReplaceMeasuringEta(logger) as Lang.Boolean {
        return !RideStreakCalculator.shouldDisplay(true, :measuring, 1);
    }

    (:test)
    static function paceResultReplacesStreak(logger) as Lang.Boolean {
        return !RideStreakCalculator.shouldDisplay(true, :ahead, 7)
            && !RideStreakCalculator.shouldDisplay(true, :behind, 7)
            && !RideStreakCalculator.shouldDisplay(true, :on_pace, 7);
    }

    private static function streak(items as Lang.Array,
            activeRideToday as Lang.Boolean) as Lang.Number {
        var today = Gregorian.info(midday(2026, 9, 14), Time.FORMAT_SHORT);
        return RideStreakCalculator.countFrom(
            new StreakHistoryIterator(items), today, activeRideToday);
    }

    private static function ride(year as Lang.Number, month as Lang.Number,
            day as Lang.Number) as StreakHistoryItem {
        return new StreakHistoryItem(midday(year, month, day), Activity.SPORT_CYCLING);
    }

    private static function midday(year as Lang.Number, month as Lang.Number,
            day as Lang.Number) as Time.Moment {
        var midnight = Gregorian.moment({:year=>year, :month=>month, :day=>day});
        return new Time.Moment(midnight.value() + 43200);
    }
}
