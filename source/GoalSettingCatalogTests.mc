using Toybox.Lang;
using Toybox.Application;

class GoalSettingCatalogTests {
    (:test)
    static function catalogUsesRequestedGoalMenuOrder(logger) as Lang.Boolean {
        var definitions = GoalSettingCatalog.goalDefinitions();
        return definitions.size() == 9
            && definitions[0].kind == :yearly
            && definitions[1].kind == :monthly
            && definitions[2].kind == :weekly
            && definitions[3].kind == :daily
            && definitions[4].kind == :daily_elevation
            && definitions[5].kind == :long_day_distance
            && definitions[6].kind == :long_day_elevation
            && definitions[7].kind == :bonus
            && definitions[8].kind == :bonus_elevation;
    }

    (:test)
    static function catalogUsesRequestedHabitMenuOrder(logger) as Lang.Boolean {
        var definitions = GoalSettingCatalog.habitDefinitions();
        return definitions.size() == 4
            && definitions[0].kind == :rest_weekdays
            && definitions[1].kind == :long_days
            && definitions[2].kind == :weekday_distance_limit
            && definitions[3].kind == :weekday_elevation_limit
            && GoalSettingCatalog.orderedDefinitions().size() == 13;
    }

    (:test)
    static function catalogPreservesPickerRules(logger) as Lang.Boolean {
        var yearly = GoalSettingCatalog.definition(:yearly);
        var longDistance = GoalSettingCatalog.definition(:long_day_distance);
        var distanceLimit = GoalSettingCatalog.definition(:weekday_distance_limit);
        return yearly.maximum == 50000 && yearly.step == 100
            && longDistance.maximum == 500 && longDistance.step == 5
            && distanceLimit.zeroLabel.equals("NO LIMIT");
    }

    (:test)
    static function largerDistanceGoalsShowCurrentValues(logger) as Lang.Boolean {
        var goals = GoalStore.getGoals();
        var suffix = " " + DistanceUnits.label();
        return GoalSettingCatalog.definition(:yearly).menuDetail().equals(
                DistanceUnits.fromMeters(goals.yearlyMeters).format("%.0f") + suffix)
            && GoalSettingCatalog.definition(:monthly).menuDetail().equals(
                DistanceUnits.fromMeters(goals.monthlyMeters).format("%.0f") + suffix)
            && GoalSettingCatalog.definition(:weekly).menuDetail().equals(
                DistanceUnits.fromMeters(goals.weeklyMeters).format("%.0f") + suffix);
    }

    (:test)
    static function automaticDailyDistanceExplainsItsSource(logger) as Lang.Boolean {
        var todayKey = GoalDate.todayKey();
        var original = GoalStore.getDailyOverride(todayKey);
        GoalStore.saveDailyOverride(todayKey, null);
        var detail = GoalSettingCatalog.definition(:daily).menuDetail();
        GoalStore.saveDailyOverride(todayKey, original);
        return detail.equals("AUTO based on larger goals");
    }

    (:test)
    static function customDailyDistanceShowsCurrentValue(logger) as Lang.Boolean {
        var todayKey = GoalDate.todayKey();
        var original = GoalStore.getDailyOverride(todayKey);
        GoalStore.saveDailyOverride(todayKey, DistanceUnits.toMeters(30));
        var detail = GoalSettingCatalog.definition(:daily).menuDetail();
        GoalStore.saveDailyOverride(todayKey, original);
        return detail.equals("30 " + DistanceUnits.label());
    }

    (:test)
    static function dailyElevationShowsCurrentValue(logger) as Lang.Boolean {
        var meters = GoalStore.getDailyElevationGoal();
        return GoalSettingCatalog.definition(:daily_elevation).menuDetail().equals(
            ElevationUnits.fromMeters(meters).format("%.0f")
                + " " + ElevationUnits.label());
    }

    (:test)
    static function catalogPersistsCountSetting(logger) as Lang.Boolean {
        var definition = GoalSettingCatalog.definition(:rest_weekdays);
        var original = GoalStore.getRestWeekdays();
        definition.saveValue(3);
        var stored = definition.currentValue();
        definition.saveValue(original);
        return stored == 3;
    }

    (:test)
    static function catalogPersistsNamedDistanceGoal(logger) as Lang.Boolean {
        var definition = GoalSettingCatalog.definition(:weekly);
        var original = GoalStore.getGoals();
        definition.saveValue(250);
        var stored = definition.currentValue();
        GoalStore.saveGoals(original);
        return stored == 250;
    }

    (:test)
    static function catalogPreservesAutoBonus(logger) as Lang.Boolean {
        var definition = GoalSettingCatalog.definition(:bonus);
        var original = GoalStore.getBonusDistanceGoal();
        definition.saveValue(0);
        var stored = GoalStore.getBonusDistanceGoal();
        GoalStore.saveBonusDistanceGoal(original);
        return stored == null && definition.zeroLabel.equals("AUTO");
    }

    (:test)
    static function weekdayElevationLimitDefaultsToTwiceDailyGoal(logger) as Lang.Boolean {
        var original = Application.Storage.getValue(WEEKDAY_ELEVATION_LIMIT_KEY);
        Application.Storage.deleteValue(WEEKDAY_ELEVATION_LIMIT_KEY);
        var limit = GoalStore.getWeekdayElevationLimit();
        restoreElevationLimit(original);
        return limit != null
            && closeTo(limit, DEFAULT_DAILY_ELEVATION_METERS * 2)
            && closeTo(ElevationUnits.fromMeters(limit), 2740.0);
    }

    (:test)
    static function explicitNoElevationLimitOverridesDefault(logger) as Lang.Boolean {
        var original = Application.Storage.getValue(WEEKDAY_ELEVATION_LIMIT_KEY);
        GoalStore.saveWeekdayElevationLimit(null);
        var limit = GoalStore.getWeekdayElevationLimit();
        restoreElevationLimit(original);
        return limit == null;
    }

    private static function restoreElevationLimit(original as Lang.Object or Null) as Void {
        if (original == null) {
            Application.Storage.deleteValue(WEEKDAY_ELEVATION_LIMIT_KEY);
        } else {
            Application.Storage.setValue(WEEKDAY_ELEVATION_LIMIT_KEY, original);
        }
    }

    private static function closeTo(actual as Lang.Numeric,
            expected as Lang.Numeric) as Lang.Boolean {
        return (actual.toFloat() - expected.toFloat()).abs() < 0.01;
    }
}
