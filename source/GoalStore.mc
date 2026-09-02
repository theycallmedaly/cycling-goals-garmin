using Toybox.Application;

class GoalStore {
    const KEYS = ["yearDistance", "monthDistance", "weekDistance", "dayDistance"];

    static function hasGoals() as Boolean {
        for (var i = 0; i < KEYS.size(); i += 1) {
            if (Application.Storage.getValue(KEYS[i]) == null) { return false; }
        }
        return true;
    }

    static function getGoals() as Array<Number> {
        var goals = [];
        for (var i = 0; i < KEYS.size(); i += 1) {
            var value = Application.Storage.getValue(KEYS[i]);
            goals.add(value == null ? 0 : value);
        }
        return goals;
    }

    static function saveGoals(goals as Array<Number>) as Void {
        for (var i = 0; i < KEYS.size(); i += 1) {
            Application.Storage.setValue(KEYS[i], goals[i]);
        }
    }
}

