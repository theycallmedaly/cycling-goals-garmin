using Toybox.Application;
using Toybox.Lang;

const YEAR_KEY = "yearDistanceMeters";
const MONTH_KEY = "monthDistanceMeters";
const WEEK_KEY = "weekDistanceMeters";
const DAILY_OVERRIDE_KEY = "dailyOverrideMeters";
const DAILY_OVERRIDE_DATE_KEY = "dailyOverrideDate";
const DEFAULT_YEAR_METERS = 11265408.0;
const DEFAULT_MONTH_METERS = 804672.0;
const DEFAULT_WEEK_METERS = 160934.4;

class GoalStore {
    static function hasGoals() as Lang.Boolean {
        return Application.Storage.getValue(YEAR_KEY) != null
            && Application.Storage.getValue(MONTH_KEY) != null
            && Application.Storage.getValue(WEEK_KEY) != null;
    }

    static function getGoals() as Lang.Array<Lang.Numeric> {
        return [
            valueOrDefault(YEAR_KEY, DEFAULT_YEAR_METERS),
            valueOrDefault(MONTH_KEY, DEFAULT_MONTH_METERS),
            valueOrDefault(WEEK_KEY, DEFAULT_WEEK_METERS)
        ];
    }

    static function saveGoals(goals as Lang.Array<Lang.Numeric>) as Void {
        Application.Storage.setValue(YEAR_KEY, goals[0]);
        Application.Storage.setValue(MONTH_KEY, goals[1]);
        Application.Storage.setValue(WEEK_KEY, goals[2]);
    }

    static function getDailyOverride(dateKey as Lang.Number) as Lang.Numeric or Null {
        if (Application.Storage.getValue(DAILY_OVERRIDE_DATE_KEY) != dateKey) { return null; }
        return Application.Storage.getValue(DAILY_OVERRIDE_KEY);
    }

    static function saveDailyOverride(dateKey as Lang.Number, meters as Lang.Numeric or Null) as Void {
        if (meters == null) {
            Application.Storage.deleteValue(DAILY_OVERRIDE_KEY);
            Application.Storage.deleteValue(DAILY_OVERRIDE_DATE_KEY);
            return;
        }
        Application.Storage.setValue(DAILY_OVERRIDE_DATE_KEY, dateKey);
        Application.Storage.setValue(DAILY_OVERRIDE_KEY, meters);
    }

    private static function valueOrDefault(key as Lang.String, defaultValue as Lang.Numeric) as Lang.Numeric {
        var value = Application.Storage.getValue(key);
        return value == null ? defaultValue : value;
    }
}
