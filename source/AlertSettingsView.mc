using Toybox.Lang;
using Toybox.WatchUi;

class AlertSettingsView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"ALERTS"});
        addToggle(menu, "All Alerts", :all_alerts);
        addToggle(menu, "Halfway Alerts", :halfway_alerts);
        addToggle(menu, "Pace Milestones", :pace_alerts);
        addToggle(menu, "Goal Complete", :goal_alerts);
        addToggle(menu, "Bonus Complete", :bonus_alerts);
        addToggle(menu, "Sound", :sound_alerts);
        return menu;
    }

    private static function addToggle(menu as WatchUi.Menu2, label as Lang.String,
            id as Lang.Symbol) as Void {
        menu.addItem(new WatchUi.ToggleMenuItem(label, null, id,
            GoalStore.alertSetting(id), {}));
    }
}

class AlertSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item instanceof WatchUi.ToggleMenuItem) {
            var toggle = item as WatchUi.ToggleMenuItem;
            var kind = toggle.getId() as Lang.Symbol;
            var enabled = toggle.isEnabled();
            GoalStore.saveAlertSetting(kind, enabled);
            if (kind == :all_alerts) {
                updateIndividualToggles(enabled);
            }
        }
    }

    private function updateIndividualToggles(enabled as Lang.Boolean) as Void {
        var settings = GoalStore.individualAlertSettings();
        for (var i = 0; i < settings.size(); i += 1) {
            var index = _menu.findItemById(settings[i]);
            if (index >= 0) {
                var item = _menu.getItem(index);
                if (item instanceof WatchUi.ToggleMenuItem) {
                    var toggle = item as WatchUi.ToggleMenuItem;
                    toggle.setEnabled(enabled);
                    _menu.updateItem(toggle, index);
                }
            }
        }
    }
}
