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

class SettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var kind = item.getId() as Lang.Symbol;
        if (kind == :goals) {
            WatchUi.pushView(GoalSetupView.createMenu(), new GoalSetupDelegate(), WatchUi.SLIDE_UP);
        } else if (kind == :habits) {
            WatchUi.pushView(HabitSettingsView.createMenu(),
                new GoalSetupDelegate(), WatchUi.SLIDE_UP);
        } else if (kind == :alerts) {
            var menu = AlertSettingsView.createMenu();
            WatchUi.pushView(menu, new AlertSettingsDelegate(menu), WatchUi.SLIDE_UP);
        } else if (kind == :about) {
            WatchUi.pushView(AboutSettingsView.createMenu(),
                new AboutSettingsDelegate(), WatchUi.SLIDE_UP);
        }
    }
}

class AboutSettingsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }
}

class GoalPickerDelegate extends WatchUi.PickerDelegate {
    private var _definition as GoalSettingDefinition;

    function initialize(kind as Lang.Symbol) {
        PickerDelegate.initialize();
        _definition = GoalSettingCatalog.definition(kind);
    }

    function onAccept(values as Lang.Array) as Lang.Boolean {
        var value = values[0] as Lang.Number;
        _definition.saveValue(value);
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
        var date = Gregorian.info(GoalRuntime.now(), Time.FORMAT_SHORT);
        return (date.year * 10000) + (date.month * 100) + date.day;
    }
}
