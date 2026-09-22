using Toybox.Lang;
using Toybox.Time;
using Toybox.UserProfile;

class GoalClock {
    function now() as Time.Moment { return Time.now(); }
}

class ActivityHistoryProvider {
    function iterator() { return UserProfile.getUserActivityHistory(); }
}

var _cyclingGoalsClock as GoalClock = new GoalClock();
var _cyclingGoalsHistoryProvider as ActivityHistoryProvider = new ActivityHistoryProvider();

class GoalRuntime {
    static function now() as Time.Moment { return _cyclingGoalsClock.now(); }

    static function activityHistoryIterator() {
        return _cyclingGoalsHistoryProvider.iterator();
    }

    static function setProvidersForTests(clock as GoalClock,
            historyProvider as ActivityHistoryProvider) as Void {
        _cyclingGoalsClock = clock;
        _cyclingGoalsHistoryProvider = historyProvider;
    }

    static function resetProviders() as Void {
        _cyclingGoalsClock = new GoalClock();
        _cyclingGoalsHistoryProvider = new ActivityHistoryProvider();
    }
}
