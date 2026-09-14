using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class GoalSetupView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"GOALS"});
        var longDistanceText = DistanceUnits.fromMeters(
            GoalStore.getLongDayDistanceGoal()).format("%.0f") + " " + DistanceUnits.label();
        var longElevationText = ElevationUnits.fromMeters(
            GoalStore.getLongDayElevationGoal()).format("%.0f") + " " + ElevationUnits.label();
        var distanceLimit = GoalStore.getWeekdayDistanceLimit();
        var distanceLimitText = distanceLimit == null ? "NO LIMIT"
            : DistanceUnits.fromMeters(distanceLimit).format("%.0f") + " " + DistanceUnits.label();
        var elevationLimit = GoalStore.getWeekdayElevationLimit();
        var elevationLimitText = elevationLimit == null ? "NO LIMIT"
            : ElevationUnits.fromMeters(elevationLimit).format("%.0f") + " " + ElevationUnits.label();
        menu.addItem(new WatchUi.MenuItem("Daily distance", "Auto or custom", :daily, {}));
        menu.addItem(new WatchUi.MenuItem("Daily elevation", "Current ride only", :daily_elevation, {}));
        menu.addItem(new WatchUi.MenuItem("Number of Rest Weekdays",
            GoalStore.getRestWeekdays().toString(), :rest_weekdays, {}));
        menu.addItem(new WatchUi.MenuItem("Number of Long Days",
            GoalStore.getLongDays().toString(), :long_days, {}));
        menu.addItem(new WatchUi.MenuItem("Long Day Distance", longDistanceText,
            :long_day_distance, {}));
        menu.addItem(new WatchUi.MenuItem("Long Day Elevation", longElevationText,
            :long_day_elevation, {}));
        menu.addItem(new WatchUi.MenuItem("Weekday Distance Limit", distanceLimitText,
            :weekday_distance_limit, {}));
        menu.addItem(new WatchUi.MenuItem("Weekday Elevation Limit", elevationLimitText,
            :weekday_elevation_limit, {}));
        menu.addItem(new WatchUi.MenuItem("Daily Bonus Distance", "Auto: 50% of daily", :bonus, {}));
        menu.addItem(new WatchUi.MenuItem("Daily Bonus Elevation", "Auto: daily elevation", :bonus_elevation, {}));
        menu.addItem(new WatchUi.MenuItem("Weekly distance", null, :weekly, {}));
        menu.addItem(new WatchUi.MenuItem("Monthly distance", null, :monthly, {}));
        menu.addItem(new WatchUi.MenuItem("Yearly distance", null, :yearly, {}));
        return menu;
    }
}

class SettingsView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"SETTINGS"});
        menu.addItem(new WatchUi.MenuItem("Goals", null, :goals, {}));
        menu.addItem(new WatchUi.MenuItem("Alerts", null, :alerts, {}));
        return menu;
    }
}

class GoalPicker extends WatchUi.Picker {
    private var _factory as GoalValueFactory;

    function initialize(kind as Lang.Symbol) {
        var goal = goalForKind(kind);
        var step = stepForKind(kind);
        var maximum = maximumForKind(kind);
        var zeroLabel = kind == :daily || kind == :bonus || kind == :bonus_elevation
            ? "AUTO"
            : (kind == :weekday_distance_limit || kind == :weekday_elevation_limit
                ? "NO LIMIT" : null);
        _factory = new GoalValueFactory(0, maximum, step,
            zeroLabel);

        var title = new WatchUi.Text({
            :text=>pickerTitle(kind),
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_SMALL,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM
        });

        Picker.initialize({
            :title=>title,
            :pattern=>[_factory],
            :defaults=>[_factory.getIndex(goal)]
        });
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Edge devices can retain the previously selected text while the
        // native picker advances. Clear first so every arrow press visibly
        // replaces the value that Picker.onUpdate() draws.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    private function goalForKind(kind as Lang.Symbol) as Lang.Number {
        if (kind == :rest_weekdays) { return GoalStore.getRestWeekdays(); }
        if (kind == :long_days) { return GoalStore.getLongDays(); }
        if (kind == :long_day_distance) {
            return DistanceUnits.fromMeters(GoalStore.getLongDayDistanceGoal()).toNumber();
        }
        if (kind == :long_day_elevation) {
            return ElevationUnits.fromMeters(GoalStore.getLongDayElevationGoal()).toNumber();
        }
        if (kind == :weekday_distance_limit) {
            var distanceLimit = GoalStore.getWeekdayDistanceLimit();
            return distanceLimit == null ? 0 : DistanceUnits.fromMeters(distanceLimit).toNumber();
        }
        if (kind == :weekday_elevation_limit) {
            var elevationLimit = GoalStore.getWeekdayElevationLimit();
            return elevationLimit == null ? 0 : ElevationUnits.fromMeters(elevationLimit).toNumber();
        }
        if (kind == :daily_elevation) {
            return ElevationUnits.fromMeters(GoalStore.getDailyElevationGoal()).toNumber();
        }
        if (kind == :bonus_elevation) {
            var elevationBonus = GoalStore.getBonusElevationGoal();
            return elevationBonus == null ? 0 : ElevationUnits.fromMeters(elevationBonus).toNumber();
        }
        if (kind == :bonus) {
            var bonus = GoalStore.getBonusDistanceGoal();
            return bonus == null ? 0 : DistanceUnits.fromMeters(bonus).toNumber();
        }
        var goals = GoalStore.getGoals();
        var meters;
        if (kind == :yearly) { meters = goals[0]; }
        else if (kind == :monthly) { meters = goals[1]; }
        else if (kind == :weekly) { meters = goals[2]; }
        else { meters = GoalStore.getDailyOverride(GoalDate.todayKey()); }
        return meters == null ? 0 : DistanceUnits.fromMeters(meters).toNumber();
    }

    private function stepForKind(kind as Lang.Symbol) as Lang.Number {
        if (kind == :rest_weekdays || kind == :long_days) { return 1; }
        if (kind == :long_day_distance) { return 5; }
        if (kind == :long_day_elevation) { return 100; }
        if (kind == :yearly) { return 100; }
        if (kind == :monthly) { return 10; }
        if (kind == :weekly) { return 5; }
        return 1;
    }

    private function maximumForKind(kind as Lang.Symbol) as Lang.Number {
        if (kind == :rest_weekdays) { return 5; }
        if (kind == :long_days) { return 2; }
        if (kind == :long_day_distance) { return 500; }
        if (kind == :long_day_elevation) { return 20000; }
        if (kind == :weekday_elevation_limit) { return 20000; }
        if (kind == :weekday_distance_limit) { return 500; }
        if (kind == :daily_elevation || kind == :bonus_elevation) { return 20000; }
        if (kind == :yearly) { return 50000; }
        if (kind == :monthly) { return 5000; }
        if (kind == :weekly) { return 1000; }
        return 500;
    }

    private function pickerTitle(kind as Lang.Symbol) as Lang.String {
        if (kind == :rest_weekdays) { return "REST WEEKDAYS PER WEEK"; }
        if (kind == :long_days) { return "LONG DAYS PER WEEK"; }
        if (kind == :long_day_distance) {
            return "LONG DAY DISTANCE (" + DistanceUnits.label() + ")";
        }
        if (kind == :long_day_elevation) {
            return "LONG DAY ELEVATION (" + ElevationUnits.label() + ")";
        }
        if (kind == :weekday_distance_limit) {
            return "WEEKDAY LIMIT (" + DistanceUnits.label() + ")";
        }
        if (kind == :weekday_elevation_limit) {
            return "WEEKDAY LIMIT (" + ElevationUnits.label() + ")";
        }
        if (kind == :daily_elevation) {
            return "DAILY ELEVATION (" + ElevationUnits.label() + ")";
        }
        if (kind == :bonus_elevation) {
            return "BONUS ELEVATION (" + ElevationUnits.label() + ")";
        }
        return (kind == :bonus ? "BONUS" : kind.toString().toUpper())
            + " DISTANCE (" + DistanceUnits.label() + ")";
    }
}

class GoalValueFactory extends WatchUi.PickerFactory {
    private var _minimum as Lang.Number;
    private var _maximum as Lang.Number;
    private var _step as Lang.Number;
    private var _zeroLabel as Lang.String or Null;

    function initialize(minimum as Lang.Number, maximum as Lang.Number, step as Lang.Number,
            zeroLabel as Lang.String or Null) {
        PickerFactory.initialize();
        _minimum = minimum;
        _maximum = maximum;
        _step = step;
        _zeroLabel = zeroLabel;
    }

    function getIndex(value as Lang.Number) as Lang.Number {
        var bounded = value > _maximum ? _maximum : value;
        return ((bounded - _minimum) / _step).toNumber();
    }

    function getDrawable(index as Lang.Number, isSelected as Lang.Boolean) as WatchUi.Drawable or Null {
        var value = getValue(index) as Lang.Number;
        var text = _zeroLabel != null && value == 0
            ? (_zeroLabel as Lang.String) : value.toString();
        return new WatchUi.Text({
            :text=>text,
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_LARGE,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_CENTER
        });
    }

    function getValue(index as Lang.Number) as Lang.Object or Null {
        return _minimum + (index * _step);
    }

    function getSize() as Lang.Number {
        return ((_maximum - _minimum) / _step).toNumber() + 1;
    }
}
