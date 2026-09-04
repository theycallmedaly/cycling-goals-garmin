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
    function initialize() { Menu2InputDelegate.initialize(); }

    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item instanceof WatchUi.ToggleMenuItem) {
            var toggle = item as WatchUi.ToggleMenuItem;
            GoalStore.saveAlertSetting(toggle.getId() as Lang.Symbol, toggle.isEnabled());
        }
    }
}
