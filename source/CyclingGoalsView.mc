using Toybox.Activity;
using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsView extends WatchUi.DataField {
    private var _recentPace as RecentPaceEstimator;
    private var _etaTrend as EtaTrendEstimator;
    private var _distanceRideGoal as RideGoalState;
    private var _elevationRideGoal as RideGoalState;
    private var _distanceMilestones as MilestoneTracker;
    private var _elevationMilestones as MilestoneTracker;
    private var _distanceBonusRoundsAlerted as Lang.Number = 0;
    private var _elevationBonusRoundsAlerted as Lang.Number = 0;
    private var _rideEnded as Lang.Boolean = false;
    private var _sawActiveTimer as Lang.Boolean = false;
    private var _lastRideDistance as Lang.Float = -1.0;
    private var _lastTimerTime as Lang.Number = -1;
    private var _screenWidth as Lang.Number = 246;
    private var _screenState as CyclingGoalsScreenState;
    private var _renderer as CyclingGoalsRenderer;

    function initialize() {
        DataField.initialize();
        _recentPace = new RecentPaceEstimator();
        _etaTrend = new EtaTrendEstimator();
        _distanceRideGoal = new RideGoalState();
        _elevationRideGoal = new RideGoalState();
        _distanceMilestones = new MilestoneTracker();
        _elevationMilestones = new MilestoneTracker();
        _screenState = new CyclingGoalsScreenState(_distanceRideGoal, _elevationRideGoal);
        _renderer = new CyclingGoalsRenderer();
    }

    function compute(info as Activity.Info) {
        _screenState.configured = GoalStore.hasGoals();
        if (!_screenState.configured) { return "SET GOALS"; }
        updateRideLifecycle(info);

        var distanceState = GoalCalculator.distanceStateForToday(info);
        var distanceEvent = _distanceMilestones.update(
            distanceState.remainingMeters, distanceState.targetMeters,
            GoalStore.alertEnabled(:halfway), GoalStore.alertEnabled(:goal));
        showRequiredMilestone(distanceEvent, false, distanceState.remainingMeters);
        _screenState.distanceWeekdayLimitApplied = distanceState.weekdayLimitApplied;
        var distanceBonusTarget = GoalCalculator.bonusTarget(
            distanceState.automaticTargetMeters, GoalStore.getBonusDistanceGoal());
        _distanceRideGoal.update(distanceState.remainingMeters, distanceState.targetMeters,
            distanceState.completedTodayMeters, distanceBonusTarget, _rideEnded);
        if (isBonusActive(_distanceRideGoal)) {
            updateBonusMilestone(_distanceRideGoal.bonusProgressMeters,
                _distanceRideGoal, false);
        }

        var elevationState = GoalCalculator.elevationStateForToday(
            info, distanceState.availableToday);
        var elevationEvent = _elevationMilestones.update(
            elevationState.remainingMeters, elevationState.targetMeters,
            GoalStore.alertEnabled(:halfway), GoalStore.alertEnabled(:goal));
        showRequiredMilestone(elevationEvent, true, elevationState.remainingMeters);
        _screenState.elevationWeekdayLimitApplied = elevationState.weekdayLimitApplied;
        var completedElevation = info.totalAscent == null ? 0.0 : info.totalAscent.toFloat();
        var elevationBonusTarget = GoalCalculator.elevationBonusTarget(
            elevationState.targetMeters, GoalStore.getBonusElevationGoal());
        _elevationRideGoal.update(elevationState.remainingMeters, elevationState.targetMeters,
            completedElevation, elevationBonusTarget, _rideEnded);
        if (isBonusActive(_elevationRideGoal)) {
            updateBonusMilestone(_elevationRideGoal.bonusProgressMeters,
                _elevationRideGoal, true);
        }

        updateEta(info);
        _screenState.rideStreakCount = RideStreakCalculator.count(_sawActiveTimer);
        _screenState.showRideStreak = RideStreakCalculator.shouldDisplay(
            _sawActiveTimer, _screenState.etaTrendState,
            _screenState.rideStreakCount);
        return DistanceUnits.fromMeters(_distanceRideGoal.remainingMeters);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        _renderer.draw(dc, _screenState);
    }

    function isBonusPromptVisible() as Lang.Boolean {
        return _distanceRideGoal.displayMode == :bonus_prompt
            || _elevationRideGoal.displayMode == :bonus_prompt;
    }

    function chooseBonusAt(x as Lang.Number) as Void {
        if (!isBonusPromptVisible()) { return; }
        var accepted = x < (_screenWidth / 2);
        if (_distanceRideGoal.displayMode == :bonus_prompt) {
            _distanceRideGoal.chooseBonus(accepted);
        } else {
            _elevationRideGoal.chooseBonus(accepted);
        }
        WatchUi.requestUpdate();
    }

    private function updateEta(info as Activity.Info) as Void {
        if (info.elapsedDistance != null && info.timerTime != null) {
            var speed = _recentPace.update(
                info.elapsedDistance, info.timerTime, info.averageSpeed);
            _screenState.etaText = RecentPaceEstimator.formatEta(
                _distanceRideGoal.remainingMeters, speed);
            var trend = _etaTrend.update(
                info.timerTime, _distanceRideGoal.remainingMeters, speed);
            _screenState.etaTrendState = trend.trend;
            _screenState.etaTrendMinutes = trend.minutes;
        } else {
            _screenState.etaText = RecentPaceEstimator.formatEta(
                _distanceRideGoal.remainingMeters, info.averageSpeed);
            _screenState.etaTrendState = :measuring;
            _screenState.etaTrendMinutes = 0;
        }
    }

    private function updateRideLifecycle(info as Activity.Info) as Void {
        var distance = info.elapsedDistance == null ? -1.0 : info.elapsedDistance.toFloat();
        var timer = info.timerTime == null ? -1 : info.timerTime.toNumber();
        if ((_lastRideDistance >= 0 && distance >= 0 && distance < _lastRideDistance)
                || (_lastTimerTime >= 0 && timer >= 0 && timer < _lastTimerTime)) {
            _distanceRideGoal.resetBonus();
            _elevationRideGoal.resetBonus();
            _distanceBonusRoundsAlerted = 0;
            _elevationBonusRoundsAlerted = 0;
            _rideEnded = false;
            _sawActiveTimer = false;
            _distanceMilestones.reset();
            _elevationMilestones.reset();
        }
        _lastRideDistance = distance;
        _lastTimerTime = timer;

        if (info.timerState == Activity.TIMER_STATE_ON) {
            _sawActiveTimer = true;
        } else if (info.timerState == Activity.TIMER_STATE_STOPPED && _sawActiveTimer) {
            _rideEnded = true;
        }
    }

    private function showRequiredMilestone(event as Lang.Symbol,
            isElevation as Lang.Boolean, remaining as Lang.Numeric) as Void {
        if (event == :none) { return; }
        var isComplete = event == :complete;
        var title = isComplete ? "GOAL COMPLETE" : "HALFWAY THERE";
        var detail;
        var icon;
        if (isElevation) {
            detail = isComplete ? "0 " + ElevationUnits.label() + " TO GO"
                : ElevationUnits.fromMeters(remaining).format("%.0f") + " "
                    + ElevationUnits.label() + " TO GO";
            icon = isComplete ? :elevation_complete : :elevation;
        } else {
            detail = isComplete ? "0.0 " + DistanceUnits.label() + " TO GO"
                : DistanceUnits.fromMeters(remaining).format("%.1f") + " "
                    + DistanceUnits.label() + " REMAINING";
            icon = isComplete ? :distance_complete : :distance;
        }
        if (WatchUi.DataField has :showAlert) {
            WatchUi.DataField.showAlert(new MilestoneAlertView(title, detail, icon));
        }
        if (GoalStore.alertEnabled(:sound) && (Attention has :playTone)) {
            Attention.playTone(isComplete
                ? Attention.TONE_SUCCESS : Attention.TONE_DISTANCE_ALERT);
        }
    }

    private function isBonusActive(goal as RideGoalState) as Lang.Boolean {
        return goal.displayMode == :bonus || goal.displayMode == :bonus_prompt;
    }

    private function updateBonusMilestone(progress as Lang.Numeric,
            goal as RideGoalState, isElevation as Lang.Boolean) as Void {
        var alertedRounds = isElevation
            ? _elevationBonusRoundsAlerted : _distanceBonusRoundsAlerted;
        if (!GoalCalculator.bonusRoundCompleted(progress, goal.bonusTargetMeters,
                goal.bonusRoundsAccepted, alertedRounds)) { return; }
        if (isElevation) {
            _elevationBonusRoundsAlerted = goal.bonusRoundsAccepted;
        } else {
            _distanceBonusRoundsAlerted = goal.bonusRoundsAccepted;
        }
        showBonusCompleteAlert(isElevation);
    }

    private function showBonusCompleteAlert(isElevation as Lang.Boolean) as Void {
        if (!GoalStore.alertEnabled(:bonus)) { return; }
        if (WatchUi.DataField has :showAlert) {
            WatchUi.DataField.showAlert(new MilestoneAlertView(
                "BONUS COMPLETE",
                isElevation ? "0 " + ElevationUnits.label() + " TO GO"
                    : "0.0 " + DistanceUnits.label() + " TO GO",
                isElevation ? :elevation_bonus_complete : :distance_bonus_complete));
        }
        if (GoalStore.alertEnabled(:sound) && (Attention has :playTone)) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
    }
}
