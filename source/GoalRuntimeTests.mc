using Toybox.Activity;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class FixedGoalClock extends GoalClock {
    private var _moment as Time.Moment;

    function initialize(moment as Time.Moment) { _moment = moment; }
    function now() as Time.Moment { return _moment; }
}

class FakeHistoryItem {
    var startTime as Time.Moment;
    var distance as Lang.Float;
    var type as Lang.Number;

    function initialize(startTime as Time.Moment, distance as Lang.Numeric,
            type as Lang.Number) {
        self.startTime = startTime;
        self.distance = distance.toFloat();
        self.type = type;
    }
}

class FakeHistoryIterator {
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

class FakeActivityHistoryProvider extends ActivityHistoryProvider {
    private var _items as Lang.Array;

    function initialize(items as Lang.Array) { _items = items; }
    function iterator() { return new FakeHistoryIterator(_items); }
}

class GoalRuntimeTests {
    (:test)
    static function injectedClockMakesTodayKeyDeterministic(logger) as Lang.Boolean {
        var fixed = middayMoment(2026, 9, 14);
        GoalRuntime.setProvidersForTests(
            new FixedGoalClock(fixed), new FakeActivityHistoryProvider([]));
        var key = GoalDate.todayKey();
        GoalRuntime.resetProviders();
        return key == 20260914;
    }

    (:test)
    static function injectedHistoryControlsCompletedToday(logger) as Lang.Boolean {
        var fixed = middayMoment(2026, 9, 14);
        var history = [new FakeHistoryItem(fixed, 100, Activity.SPORT_CYCLING)];
        var todayKey = 20260914;
        var originalOverride = GoalStore.getDailyOverride(todayKey);
        GoalStore.saveDailyOverride(todayKey, 1000.0);
        GoalRuntime.setProvidersForTests(
            new FixedGoalClock(fixed), new FakeActivityHistoryProvider(history));

        var state = GoalCalculator.distanceStateForToday(
            new CharacterizationActivityInfo(25.0, 0));

        GoalRuntime.resetProviders();
        GoalStore.saveDailyOverride(todayKey, originalOverride);
        return closeTo(state.completedTodayMeters, 125.0)
            && closeTo(state.remainingMeters, 875.0);
    }

    private static function closeTo(actual as Lang.Numeric,
            expected as Lang.Numeric) as Lang.Boolean {
        var difference = actual.toFloat() - expected.toFloat();
        if (difference < 0) { difference = -difference; }
        return difference < 0.01;
    }

    private static function middayMoment(year as Lang.Number, month as Lang.Number,
            day as Lang.Number) as Time.Moment {
        var midnight = Gregorian.moment({:year=>year, :month=>month, :day=>day});
        return new Time.Moment(midnight.value() + 43200);
    }
}
