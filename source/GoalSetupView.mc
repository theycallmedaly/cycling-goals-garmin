using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class GoalSetupView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"GOALS"});
        var definitions = GoalSettingCatalog.goalDefinitions();
        for (var i = 0; i < definitions.size(); i += 1) {
            var definition = definitions[i];
            menu.addItem(new WatchUi.MenuItem(definition.label,
                definition.menuDetail(), definition.kind, {}));
        }
        return menu;
    }
}

class HabitSettingsView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"HABITS"});
        var definitions = GoalSettingCatalog.habitDefinitions();
        for (var i = 0; i < definitions.size(); i += 1) {
            var definition = definitions[i];
            menu.addItem(new WatchUi.MenuItem(definition.label,
                definition.menuDetail(), definition.kind, {}));
        }
        return menu;
    }
}

class AboutSettingsView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"ABOUT"});
        menu.addItem(new WatchUi.MenuItem("Developer", "Aaron Daly",
            :developer, {}));
        menu.addItem(new WatchUi.MenuItem("Version", "0.1.0",
            :version, {}));
        return menu;
    }
}

class SettingsView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"SETTINGS"});
        menu.addItem(new WatchUi.MenuItem("Goals", null, :goals, {}));
        menu.addItem(new WatchUi.MenuItem("Habits", null, :habits, {}));
        menu.addItem(new WatchUi.MenuItem("Alerts", null, :alerts, {}));
        menu.addItem(new WatchUi.MenuItem("About", null, :about, {}));
        return menu;
    }
}

class GoalPicker extends WatchUi.Picker {
    private var _factory as GoalValueFactory;

    function initialize(kind as Lang.Symbol) {
        var definition = GoalSettingCatalog.definition(kind);
        _factory = new GoalValueFactory(definition.minimum, definition.maximum,
            definition.step, definition.zeroLabel);
        var title = new WatchUi.Text({
            :text=>definition.pickerTitle(),
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_SMALL,
            :locX=>WatchUi.LAYOUT_HALIGN_CENTER,
            :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM
        });
        Picker.initialize({
            :title=>title,
            :pattern=>[_factory],
            :defaults=>[_factory.getIndex(definition.currentValue())]
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
}

class GoalValueFactory extends WatchUi.PickerFactory {
    private var _minimum as Lang.Number;
    private var _maximum as Lang.Number;
    private var _step as Lang.Number;
    private var _zeroLabel as Lang.String or Null;

    function initialize(minimum as Lang.Number, maximum as Lang.Number,
            step as Lang.Number, zeroLabel as Lang.String or Null) {
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

    function getDrawable(index as Lang.Number,
            isSelected as Lang.Boolean) as WatchUi.Drawable or Null {
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
