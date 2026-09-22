using Toybox.Lang;

// Named replacements for scheduling tuples. Scheduling helpers migrate to
// these types separately so the change can be validated in small steps.
class ScheduleCounts {
    var weekdaySlots as Lang.Number;
    var ordinaryWeekendSlots as Lang.Number;
    var longDaySlots as Lang.Number;

    function initialize(weekdaySlots as Lang.Number, ordinaryWeekendSlots as Lang.Number,
            longDaySlots as Lang.Number) {
        self.weekdaySlots = weekdaySlots;
        self.ordinaryWeekendSlots = ordinaryWeekendSlots;
        self.longDaySlots = longDaySlots;
    }
}

class ScheduledTarget {
    var targetMeters as Lang.Float;
    var weekdayLimitApplied as Lang.Boolean;

    function initialize(targetMeters as Lang.Numeric, weekdayLimitApplied as Lang.Boolean) {
        self.targetMeters = targetMeters.toFloat();
        self.weekdayLimitApplied = weekdayLimitApplied;
    }
}

class ScheduledAutomaticTarget {
    var targetMeters as Lang.Float;
    var weekdayLimitApplied as Lang.Boolean;
    var availableToday as Lang.Boolean;

    function initialize(targetMeters as Lang.Numeric, weekdayLimitApplied as Lang.Boolean,
            availableToday as Lang.Boolean) {
        self.targetMeters = targetMeters.toFloat();
        self.weekdayLimitApplied = weekdayLimitApplied;
        self.availableToday = availableToday;
    }
}
