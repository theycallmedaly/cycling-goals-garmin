using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class GoalSetupView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"GOALS"});
        menu.addItem(new WatchUi.MenuItem("Daily distance", "Auto or custom", :daily, {}));
        menu.addItem(new WatchUi.MenuItem("Daily elevation", "Current ride only", :daily_elevation, {}));
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
        _factory = new GoalValueFactory(0, maximum, step,
            kind == :daily || kind == :bonus || kind == :bonus_elevation);

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

    private function goalForKind(kind as Lang.Symbol) as Lang.Number {
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
        if (kind == :yearly) { return 100; }
        if (kind == :monthly) { return 10; }
        if (kind == :weekly) { return 5; }
        return 1;
    }

    private function maximumForKind(kind as Lang.Symbol) as Lang.Number {
        if (kind == :daily_elevation || kind == :bonus_elevation) { return 20000; }
        if (kind == :yearly) { return 50000; }
        if (kind == :monthly) { return 5000; }
        if (kind == :weekly) { return 1000; }
        return 500;
    }

    private function pickerTitle(kind as Lang.Symbol) as Lang.String {
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
    private var _zeroIsAuto as Lang.Boolean;

    function initialize(minimum as Lang.Number, maximum as Lang.Number, step as Lang.Number,
            zeroIsAuto as Lang.Boolean) {
        PickerFactory.initialize();
        _minimum = minimum;
        _maximum = maximum;
        _step = step;
        _zeroIsAuto = zeroIsAuto;
    }

    function getIndex(value as Lang.Number) as Lang.Number {
        var bounded = value > _maximum ? _maximum : value;
        return ((bounded - _minimum) / _step).toNumber();
    }

    function getDrawable(index as Lang.Number, isSelected as Lang.Boolean) as WatchUi.Drawable or Null {
        var value = getValue(index) as Lang.Number;
        var text = _zeroIsAuto && value == 0 ? "AUTO" : value.toString();
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
