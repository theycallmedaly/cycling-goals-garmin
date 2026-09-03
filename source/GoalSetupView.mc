using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class GoalSetupView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"UPDATE GOALS"});
        menu.addItem(new WatchUi.MenuItem("Daily", "Auto or override", :daily, {}));
        menu.addItem(new WatchUi.MenuItem("Weekly", null, :weekly, {}));
        menu.addItem(new WatchUi.MenuItem("Monthly", null, :monthly, {}));
        menu.addItem(new WatchUi.MenuItem("Yearly", null, :yearly, {}));
        return menu;
    }
}

class GoalPicker extends WatchUi.Picker {
    private var _factory as GoalValueFactory;

    function initialize(kind as Lang.Symbol) {
        var goal = goalForKind(kind);
        var step = stepForKind(kind);
        var maximum = maximumForKind(kind);
        _factory = new GoalValueFactory(0, maximum, step);

        var title = new WatchUi.Text({
            :text=>kind.toString().toUpper() + " DISTANCE (" + DistanceUnits.label() + ")",
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
        if (kind == :yearly) { return 50000; }
        if (kind == :monthly) { return 5000; }
        if (kind == :weekly) { return 1000; }
        return 500;
    }
}

class GoalValueFactory extends WatchUi.PickerFactory {
    private var _minimum as Lang.Number;
    private var _maximum as Lang.Number;
    private var _step as Lang.Number;

    function initialize(minimum as Lang.Number, maximum as Lang.Number, step as Lang.Number) {
        PickerFactory.initialize();
        _minimum = minimum;
        _maximum = maximum;
        _step = step;
    }

    function getIndex(value as Lang.Number) as Lang.Number {
        var bounded = value > _maximum ? _maximum : value;
        return ((bounded - _minimum) / _step).toNumber();
    }

    function getDrawable(index as Lang.Number, isSelected as Lang.Boolean) as WatchUi.Drawable or Null {
        var value = getValue(index) as Lang.Number;
        var text = value == 0 ? "AUTO" : value.toString();
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
