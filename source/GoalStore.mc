using Toybox.Application;
using Toybox.Lang;

const YEAR_KEY = "yearDistanceMeters";
const MONTH_KEY = "monthDistanceMeters";
const WEEK_KEY = "weekDistanceMeters";
const DAILY_OVERRIDE_KEY = "dailyOverrideMeters";
const DAILY_OVERRIDE_DATE_KEY = "dailyOverrideDate";

class GoalStore {
    static function hasGoals() as Lang.Boolean {
        return Application.Storage.getValue(YEAR_KEY) != null
            && Application.Storage.getValue(MONTH_KEY) != null
            && Application.Storage.getValue(WEEK_KEY) != null;
    }

    static function getGoals() as Lang.Array<Lang.Numeric> {
        return [valueOrZero(YEAR_KEY), valueOrZero(MONTH_KEY), valueOrZero(WEEK_KEY)];
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

    private static function valueOrZero(key as Lang.String) as Lang.Numeric {
        var value = Application.Storage.getValue(key);
        return value == null ? 0 : value;
    }
}
