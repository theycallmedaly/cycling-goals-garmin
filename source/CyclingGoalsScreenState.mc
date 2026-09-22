using Toybox.Lang;

class CyclingGoalsScreenState {
    var configured as Lang.Boolean = false;
    var distanceGoal as RideGoalState;
    var elevationGoal as RideGoalState;
    var distanceWeekdayLimitApplied as Lang.Boolean = false;
    var elevationWeekdayLimitApplied as Lang.Boolean = false;
    var etaText as Lang.String = "--H:--M";
    var etaTrendState as Lang.Symbol = :measuring;
    var etaTrendMinutes as Lang.Number = 0;
    var rideStreakCount as Lang.Number = 0;
    var showRideStreak as Lang.Boolean = true;

    function initialize(distanceGoal as RideGoalState, elevationGoal as RideGoalState) {
        self.distanceGoal = distanceGoal;
        self.elevationGoal = elevationGoal;
    }
}
