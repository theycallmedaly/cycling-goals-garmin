using Toybox.Application;
using Toybox.Lang;

const YEAR_KEY = "yearDistanceMeters";
const MONTH_KEY = "monthDistanceMeters";
const WEEK_KEY = "weekDistanceMeters";
const DAILY_OVERRIDE_KEY = "dailyOverrideMeters";
const DAILY_OVERRIDE_DATE_KEY = "dailyOverrideDate";
const DAILY_ELEVATION_KEY = "dailyElevationMeters";
const BONUS_DISTANCE_KEY = "bonusDistanceMeters";
const ALL_ALERTS_KEY = "allAlerts";
const HALFWAY_ALERTS_KEY = "halfwayAlerts";
const PACE_ALERTS_KEY = "paceAlerts";
const GOAL_ALERTS_KEY = "goalAlerts";
const BONUS_ALERTS_KEY = "bonusAlerts";
const SOUND_ALERTS_KEY = "soundAlerts";
const DEFAULT_YEAR_METERS = 11265408.0;
const DEFAULT_MONTH_METERS = 804672.0;
const DEFAULT_WEEK_METERS = 160934.4;
const DEFAULT_DAILY_ELEVATION_METERS = 417.576;

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

    static function getDailyElevationGoal() as Lang.Numeric {
        return valueOrDefault(DAILY_ELEVATION_KEY, DEFAULT_DAILY_ELEVATION_METERS);
    }

    static function saveDailyElevationGoal(meters as Lang.Numeric) as Void {
        Application.Storage.setValue(DAILY_ELEVATION_KEY, meters);
    }

    // Null means AUTO: half of today's original automatic distance goal.
    static function getBonusDistanceGoal() as Lang.Numeric or Null {
        return Application.Storage.getValue(BONUS_DISTANCE_KEY);
    }

    static function saveBonusDistanceGoal(meters as Lang.Numeric or Null) as Void {
        if (meters == null) {
            Application.Storage.deleteValue(BONUS_DISTANCE_KEY);
        } else {
            Application.Storage.setValue(BONUS_DISTANCE_KEY, meters);
        }
    }

    static function alertEnabled(kind as Lang.Symbol) as Lang.Boolean {
        if (!booleanOrDefault(ALL_ALERTS_KEY, true)) { return false; }
        if (kind == :halfway) { return booleanOrDefault(HALFWAY_ALERTS_KEY, true); }
        if (kind == :pace) { return booleanOrDefault(PACE_ALERTS_KEY, true); }
        if (kind == :goal) { return booleanOrDefault(GOAL_ALERTS_KEY, true); }
        if (kind == :bonus) { return booleanOrDefault(BONUS_ALERTS_KEY, true); }
        if (kind == :sound) { return booleanOrDefault(SOUND_ALERTS_KEY, true); }
        return true;
    }

    static function alertSetting(kind as Lang.Symbol) as Lang.Boolean {
        if (kind == :all_alerts) { return booleanOrDefault(ALL_ALERTS_KEY, true); }
        if (kind == :halfway_alerts) { return booleanOrDefault(HALFWAY_ALERTS_KEY, true); }
        if (kind == :pace_alerts) { return booleanOrDefault(PACE_ALERTS_KEY, true); }
        if (kind == :goal_alerts) { return booleanOrDefault(GOAL_ALERTS_KEY, true); }
        if (kind == :bonus_alerts) { return booleanOrDefault(BONUS_ALERTS_KEY, true); }
        return booleanOrDefault(SOUND_ALERTS_KEY, true);
    }

    static function saveAlertSetting(kind as Lang.Symbol, enabled as Lang.Boolean) as Void {
        var key = SOUND_ALERTS_KEY;
        if (kind == :all_alerts) { key = ALL_ALERTS_KEY; }
        else if (kind == :halfway_alerts) { key = HALFWAY_ALERTS_KEY; }
        else if (kind == :pace_alerts) { key = PACE_ALERTS_KEY; }
        else if (kind == :goal_alerts) { key = GOAL_ALERTS_KEY; }
        else if (kind == :bonus_alerts) { key = BONUS_ALERTS_KEY; }
        Application.Storage.setValue(key, enabled);
    }

    private static function valueOrDefault(key as Lang.String, defaultValue as Lang.Numeric) as Lang.Numeric {
        var value = Application.Storage.getValue(key);
        return value == null ? defaultValue : value;
    }

    private static function booleanOrDefault(key as Lang.String, defaultValue as Lang.Boolean) as Lang.Boolean {
        var value = Application.Storage.getValue(key);
        return value == null ? defaultValue : value;
    }
}
