using Toybox.Lang;

// Named replacements for the application-owned goal tuples. Producers and
// consumers migrate to these types in a later refactor phase.
class DistanceGoals {
    var yearlyMeters as Lang.Float;
    var monthlyMeters as Lang.Float;
    var weeklyMeters as Lang.Float;

    function initialize(yearlyMeters as Lang.Numeric, monthlyMeters as Lang.Numeric,
            weeklyMeters as Lang.Numeric) {
        self.yearlyMeters = yearlyMeters.toFloat();
        self.monthlyMeters = monthlyMeters.toFloat();
        self.weeklyMeters = weeklyMeters.toFloat();
    }
}

class DistanceGoalState {
    var remainingMeters as Lang.Float;
    var targetMeters as Lang.Float;
    var completedTodayMeters as Lang.Float;
    var automaticTargetMeters as Lang.Float;
    var weekdayLimitApplied as Lang.Boolean;
    var availableToday as Lang.Boolean;

    function initialize(remainingMeters as Lang.Numeric, targetMeters as Lang.Numeric,
            completedTodayMeters as Lang.Numeric, automaticTargetMeters as Lang.Numeric,
            weekdayLimitApplied as Lang.Boolean, availableToday as Lang.Boolean) {
        self.remainingMeters = remainingMeters.toFloat();
        self.targetMeters = targetMeters.toFloat();
        self.completedTodayMeters = completedTodayMeters.toFloat();
        self.automaticTargetMeters = automaticTargetMeters.toFloat();
        self.weekdayLimitApplied = weekdayLimitApplied;
        self.availableToday = availableToday;
    }
}

class ElevationGoalState {
    var remainingMeters as Lang.Float;
    var targetMeters as Lang.Float;
    var weekdayLimitApplied as Lang.Boolean;

    function initialize(remainingMeters as Lang.Numeric, targetMeters as Lang.Numeric,
            weekdayLimitApplied as Lang.Boolean) {
        self.remainingMeters = remainingMeters.toFloat();
        self.targetMeters = targetMeters.toFloat();
        self.weekdayLimitApplied = weekdayLimitApplied;
    }
}
