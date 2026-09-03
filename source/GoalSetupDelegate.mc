using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class GoalSetupDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var kind = item.getId() as Lang.Symbol;
        WatchUi.pushView(new GoalPicker(kind), new GoalPickerDelegate(kind), WatchUi.SLIDE_UP);
    }
}

class GoalPickerDelegate extends WatchUi.PickerDelegate {
    private var _kind as Lang.Symbol;

    function initialize(kind as Lang.Symbol) {
        PickerDelegate.initialize();
        _kind = kind;
    }

    function onAccept(values as Lang.Array) as Lang.Boolean {
        var value = values[0] as Lang.Number;
        if (_kind == :daily_elevation) {
            GoalStore.saveDailyElevationGoal(ElevationUnits.toMeters(value));
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        var meters = DistanceUnits.toMeters(value);
        var goals = GoalStore.getGoals();

        if (_kind == :yearly) { goals[0] = meters; }
        else if (_kind == :monthly) { goals[1] = meters; }
        else if (_kind == :weekly) { goals[2] = meters; }
        else { GoalStore.saveDailyOverride(GoalDate.todayKey(), value == 0 ? null : meters); }

        if (_kind != :daily) { GoalStore.saveGoals(goals); }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onCancel() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}

class GoalDate {
    static function todayKey() as Lang.Number {
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (date.year * 10000) + (date.month * 100) + date.day;
    }
}
