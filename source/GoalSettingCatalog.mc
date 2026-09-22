using Toybox.Lang;

class GoalSettingDefinition {
    var kind as Lang.Symbol;
    var label as Lang.String;
    var minimum as Lang.Number;
    var maximum as Lang.Number;
    var step as Lang.Number;
    var zeroLabel as Lang.String or Null;

    function initialize(kind as Lang.Symbol, label as Lang.String,
            minimum as Lang.Number, maximum as Lang.Number, step as Lang.Number,
            zeroLabel as Lang.String or Null) {
        self.kind = kind;
        self.label = label;
        self.minimum = minimum;
        self.maximum = maximum;
        self.step = step;
        self.zeroLabel = zeroLabel;
    }

    function menuDetail() as Lang.String or Null {
        if (kind == :daily) {
            var daily = GoalStore.getDailyOverride(GoalDate.todayKey());
            return daily == null ? "AUTO based on larger goals" : distanceText(daily);
        }
        if (kind == :daily_elevation) {
            return elevationText(GoalStore.getDailyElevationGoal());
        }
        if (kind == :yearly || kind == :monthly || kind == :weekly) {
            var goals = GoalStore.getGoals();
            if (kind == :yearly) { return distanceText(goals.yearlyMeters); }
            if (kind == :monthly) { return distanceText(goals.monthlyMeters); }
            return distanceText(goals.weeklyMeters);
        }
        if (kind == :rest_weekdays) { return GoalStore.getRestWeekdays().toString(); }
        if (kind == :long_days) { return GoalStore.getLongDays().toString(); }
        if (kind == :long_day_distance) {
            return distanceText(GoalStore.getLongDayDistanceGoal());
        }
        if (kind == :long_day_elevation) {
            return elevationText(GoalStore.getLongDayElevationGoal());
        }
        if (kind == :weekday_distance_limit) {
            var distanceLimit = GoalStore.getWeekdayDistanceLimit();
            return distanceLimit == null ? "NO LIMIT" : distanceText(distanceLimit);
        }
        if (kind == :weekday_elevation_limit) {
            var elevationLimit = GoalStore.getWeekdayElevationLimit();
            return elevationLimit == null ? "NO LIMIT" : elevationText(elevationLimit);
        }
        if (kind == :bonus) { return "Auto: 50% of daily"; }
        if (kind == :bonus_elevation) { return "Auto: daily elevation"; }
        return null;
    }

    function pickerTitle() as Lang.String {
        if (kind == :rest_weekdays) { return "REST WEEKDAYS PER WEEK"; }
        if (kind == :long_days) { return "LONG DAYS PER WEEK"; }
        if (kind == :long_day_distance) {
            return "LONG DAY DISTANCE (" + DistanceUnits.label() + ")";
        }
        if (kind == :long_day_elevation) {
            return "LONG DAY ELEVATION (" + ElevationUnits.label() + ")";
        }
        if (kind == :weekday_distance_limit) {
            return "WEEKDAY LIMIT (" + DistanceUnits.label() + ")";
        }
        if (kind == :weekday_elevation_limit) {
            return "WEEKDAY LIMIT (" + ElevationUnits.label() + ")";
        }
        if (kind == :daily_elevation) {
            return "DAILY ELEVATION (" + ElevationUnits.label() + ")";
        }
        if (kind == :bonus_elevation) {
            return "BONUS ELEVATION (" + ElevationUnits.label() + ")";
        }
        return (kind == :bonus ? "BONUS" : kind.toString().toUpper())
            + " DISTANCE (" + DistanceUnits.label() + ")";
    }

    function currentValue() as Lang.Number {
        if (kind == :rest_weekdays) { return GoalStore.getRestWeekdays(); }
        if (kind == :long_days) { return GoalStore.getLongDays(); }
        if (kind == :long_day_distance) {
            return DistanceUnits.fromMeters(GoalStore.getLongDayDistanceGoal()).toNumber();
        }
        if (kind == :long_day_elevation) {
            return ElevationUnits.fromMeters(GoalStore.getLongDayElevationGoal()).toNumber();
        }
        if (kind == :weekday_distance_limit) {
            var distanceLimit = GoalStore.getWeekdayDistanceLimit();
            return distanceLimit == null ? 0
                : DistanceUnits.fromMeters(distanceLimit).toNumber();
        }
        if (kind == :weekday_elevation_limit) {
            var elevationLimit = GoalStore.getWeekdayElevationLimit();
            return elevationLimit == null ? 0
                : ElevationUnits.fromMeters(elevationLimit).toNumber();
        }
        if (kind == :daily_elevation) {
            return ElevationUnits.fromMeters(GoalStore.getDailyElevationGoal()).toNumber();
        }
        if (kind == :bonus_elevation) {
            var elevationBonus = GoalStore.getBonusElevationGoal();
            return elevationBonus == null ? 0
                : ElevationUnits.fromMeters(elevationBonus).toNumber();
        }
        if (kind == :bonus) {
            var bonus = GoalStore.getBonusDistanceGoal();
            return bonus == null ? 0 : DistanceUnits.fromMeters(bonus).toNumber();
        }
        var goals = GoalStore.getGoals();
        var meters;
        if (kind == :yearly) { meters = goals.yearlyMeters; }
        else if (kind == :monthly) { meters = goals.monthlyMeters; }
        else if (kind == :weekly) { meters = goals.weeklyMeters; }
        else { meters = GoalStore.getDailyOverride(GoalDate.todayKey()); }
        return meters == null ? 0 : DistanceUnits.fromMeters(meters).toNumber();
    }

    function saveValue(value as Lang.Number) as Void {
        if (kind == :rest_weekdays) { GoalStore.saveRestWeekdays(value); return; }
        if (kind == :long_days) { GoalStore.saveLongDays(value); return; }
        if (kind == :long_day_distance) {
            GoalStore.saveLongDayDistanceGoal(DistanceUnits.toMeters(value)); return;
        }
        if (kind == :long_day_elevation) {
            GoalStore.saveLongDayElevationGoal(ElevationUnits.toMeters(value)); return;
        }
        if (kind == :weekday_distance_limit) {
            GoalStore.saveWeekdayDistanceLimit(
                value == 0 ? null : DistanceUnits.toMeters(value)); return;
        }
        if (kind == :weekday_elevation_limit) {
            GoalStore.saveWeekdayElevationLimit(
                value == 0 ? null : ElevationUnits.toMeters(value)); return;
        }
        if (kind == :daily_elevation) {
            GoalStore.saveDailyElevationGoal(ElevationUnits.toMeters(value)); return;
        }
        if (kind == :bonus_elevation) {
            GoalStore.saveBonusElevationGoal(
                value == 0 ? null : ElevationUnits.toMeters(value)); return;
        }
        var meters = DistanceUnits.toMeters(value);
        if (kind == :bonus) {
            GoalStore.saveBonusDistanceGoal(value == 0 ? null : meters); return;
        }
        if (kind == :daily) {
            GoalStore.saveDailyOverride(
                GoalDate.todayKey(), value == 0 ? null : meters); return;
        }
        var goals = GoalStore.getGoals();
        if (kind == :yearly) { goals.yearlyMeters = meters.toFloat(); }
        else if (kind == :monthly) { goals.monthlyMeters = meters.toFloat(); }
        else { goals.weeklyMeters = meters.toFloat(); }
        GoalStore.saveGoals(goals);
    }

    private function distanceText(meters as Lang.Numeric) as Lang.String {
        return DistanceUnits.fromMeters(meters).format("%.0f")
            + " " + DistanceUnits.label();
    }

    private function elevationText(meters as Lang.Numeric) as Lang.String {
        return ElevationUnits.fromMeters(meters).format("%.0f")
            + " " + ElevationUnits.label();
    }
}

class GoalSettingCatalog {
    static function goalDefinitions() as Lang.Array<GoalSettingDefinition> {
        return [
            new GoalSettingDefinition(:yearly, "Yearly Distance", 0, 50000, 100, null),
            new GoalSettingDefinition(:monthly, "Monthly Distance", 0, 5000, 10, null),
            new GoalSettingDefinition(:weekly, "Weekly Distance", 0, 1000, 5, null),
            new GoalSettingDefinition(:daily, "Daily Distance", 0, 500, 1, "AUTO"),
            new GoalSettingDefinition(:daily_elevation, "Daily Elevation", 0, 20000, 1, null),
            new GoalSettingDefinition(:long_day_distance, "Long Day Distance", 0, 500, 5, null),
            new GoalSettingDefinition(:long_day_elevation, "Long Day Elevation", 0, 20000, 100, null),
            new GoalSettingDefinition(:bonus, "Daily Bonus Distance", 0, 500, 1, "AUTO"),
            new GoalSettingDefinition(:bonus_elevation, "Daily Bonus Elevation", 0, 20000, 1, "AUTO")
        ];
    }

    static function habitDefinitions() as Lang.Array<GoalSettingDefinition> {
        return [
            new GoalSettingDefinition(:rest_weekdays, "Number of Rest Weekdays", 0, 5, 1, null),
            new GoalSettingDefinition(:long_days, "Number of Long Days", 0, 2, 1, null),
            new GoalSettingDefinition(:weekday_distance_limit, "Weekday Distance Limit", 0, 500, 1, "NO LIMIT"),
            new GoalSettingDefinition(:weekday_elevation_limit, "Weekday Elevation Limit", 0, 20000, 1, "NO LIMIT")
        ];
    }

    static function orderedDefinitions() as Lang.Array<GoalSettingDefinition> {
        var definitions = goalDefinitions();
        var habits = habitDefinitions();
        for (var i = 0; i < habits.size(); i += 1) {
            definitions.add(habits[i]);
        }
        return definitions;
    }

    static function definition(kind as Lang.Symbol) as GoalSettingDefinition {
        var definitions = orderedDefinitions();
        for (var i = 0; i < definitions.size(); i += 1) {
            if (definitions[i].kind == kind) { return definitions[i]; }
        }
        // Callers only provide menu IDs owned by this catalog. Retain a safe
        // fallback without coupling it to an array position.
        return definition(:daily);
    }
}
