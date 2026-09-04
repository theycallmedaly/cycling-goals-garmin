using Toybox.Activity;
using Toybox.Application;
using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsView extends WatchUi.DataField {
    private var _remainingMeters as Lang.Float = 0.0;
    private var _distanceTargetMeters as Lang.Float = 0.0;
    private var _remainingElevationMeters as Lang.Float = 0.0;
    private var _elevationTargetMeters as Lang.Float = 0.0;
    private var _recentPace as RecentPaceEstimator;
    private var _etaTrend as EtaTrendEstimator;
    private var _etaText as Lang.String = "--H:--M";
    private var _etaTrendState as Lang.Symbol = :measuring;
    private var _etaTrendMinutes as Lang.Number = 0;
    private var _distanceDisplayMode as Lang.Symbol = :required;
    private var _bonusTargetMeters as Lang.Float = 0.0;
    private var _requiredTargetMeters as Lang.Float = 0.0;
    private var _completedTodayMeters as Lang.Float = 0.0;
    private var _bonusRoundsAccepted as Lang.Number = 0;
    private var _bonusOfferDeclined as Lang.Boolean = false;
    private var _rideEnded as Lang.Boolean = false;
    private var _sawActiveTimer as Lang.Boolean = false;
    private var _lastRideDistance as Lang.Float = -1.0;
    private var _lastTimerTime as Lang.Number = -1;
    private var _lastDistanceFraction as Lang.Float = -1.0;
    private var _distanceHalfwayAlerted as Lang.Boolean = false;
    private var _screenWidth as Lang.Number = 246;
    private var _configured as Lang.Boolean = false;

    function initialize() {
        DataField.initialize();
        _recentPace = new RecentPaceEstimator();
        _etaTrend = new EtaTrendEstimator();
    }

    function compute(info as Activity.Info) {
        _configured = GoalStore.hasGoals();
        if (!_configured) { return "SET GOALS"; }
        updateRideLifecycle(info);
        var distanceState = GoalCalculator.distanceStateForToday(info);
        updateDistanceMilestone(distanceState[0], distanceState[1]);
        _remainingMeters = distanceState[0];
        _distanceTargetMeters = distanceState[1];
        _requiredTargetMeters = distanceState[1];
        _completedTodayMeters = distanceState[2];
        _distanceDisplayMode = :required;
        _bonusTargetMeters = GoalCalculator.bonusTarget(
            distanceState[3], GoalStore.getBonusDistanceGoal());
        if (_remainingMeters <= 0 && _bonusTargetMeters > 0) {
            if (_rideEnded || _bonusOfferDeclined) {
                _distanceDisplayMode = :complete;
            } else {
                var bonusProgress = GoalCalculator.bonusProgress(distanceState[1], distanceState[2]);
                var acceptedBonus = _bonusTargetMeters * _bonusRoundsAccepted;
                if (_bonusRoundsAccepted == 0 || bonusProgress >= acceptedBonus) {
                    _distanceDisplayMode = :bonus_prompt;
                } else {
                    _distanceDisplayMode = :bonus;
                    _remainingMeters = acceptedBonus - bonusProgress;
                    _distanceTargetMeters = _bonusTargetMeters;
                }
            }
        }
        var elevationState = GoalCalculator.elevationStateForToday(info);
        _remainingElevationMeters = elevationState[0];
        _elevationTargetMeters = elevationState[1];
        if (info.elapsedDistance != null && info.timerTime != null) {
            var speed = _recentPace.update(info.elapsedDistance, info.timerTime, info.averageSpeed);
            _etaText = RecentPaceEstimator.formatEta(_remainingMeters, speed);
            var trend = _etaTrend.update(info.timerTime, _remainingMeters, speed);
            _etaTrendState = trend[0];
            _etaTrendMinutes = trend[1] as Lang.Number;
        } else {
            _etaText = RecentPaceEstimator.formatEta(_remainingMeters, info.averageSpeed);
            _etaTrendState = :measuring;
            _etaTrendMinutes = 0;
        }
        return DistanceUnits.fromMeters(_remainingMeters);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _screenWidth = dc.getWidth();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        if (!_configured) {
            dc.drawText(x, y - 18, Graphics.FONT_SMALL,
                Application.loadResource(Rez.Strings.NoGoals), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y + 10, Graphics.FONT_XTINY,
                Application.loadResource(Rez.Strings.OpenSettings), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        if (_distanceDisplayMode == :bonus_prompt) {
            drawBonusPrompt(dc);
            return;
        }
        var distanceStatus = progressColor(_distanceTargetMeters, _remainingMeters);
        var elevationStatus = progressColor(_elevationTargetMeters, _remainingElevationMeters);
        var etaBackground = etaColor(_etaTrendState);
        var distanceBottom = (dc.getHeight() * 37) / 100;
        var etaBottom = (dc.getHeight() * 63) / 100;
        var distanceBackground = _distanceDisplayMode == :bonus
            ? Graphics.COLOR_GREEN : Graphics.COLOR_BLACK;
        dc.setColor(distanceBackground, distanceBackground);
        dc.fillRectangle(0, 0, dc.getWidth(), distanceBottom);
        dc.setColor(etaBackground, etaBackground);
        dc.fillRectangle(0, distanceBottom, dc.getWidth(), etaBottom - distanceBottom);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, etaBottom, dc.getWidth(), dc.getHeight() - etaBottom);

        if (_distanceDisplayMode != :bonus) {
            drawStatusRails(dc, 0, distanceBottom, distanceStatus);
        }
        drawStatusRails(dc, etaBottom, dc.getHeight(), elevationStatus);

        dc.setColor(Graphics.COLOR_WHITE, distanceBackground);
        dc.drawText(x, 4, Graphics.FONT_XTINY,
            _distanceDisplayMode == :bonus ? "BONUS MILES REMAINING"
                : Application.loadResource(Rez.Strings.RemainingToday),
            Graphics.TEXT_JUSTIFY_CENTER);
        var distanceCenter = (24 + distanceBottom) / 2;
        var etaCenter = distanceBottom + ((etaBottom - distanceBottom) / 2);
        var elevationCenter = etaBottom + ((dc.getHeight() - etaBottom) / 2);

        dc.drawText(x, distanceCenter - 12, Graphics.FONT_NUMBER_THAI_HOT,
            DistanceUnits.fromMeters(_remainingMeters).format("%.2f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, distanceCenter + 14, Graphics.FONT_SMALL, DistanceUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);

        var etaForeground = etaBackground == Graphics.COLOR_GREEN ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        dc.setColor(etaForeground, etaBackground);
        dc.drawLine(24, distanceBottom, dc.getWidth() - 24, distanceBottom);
        var etaValueX = (dc.getWidth() * 33) / 100;
        var etaTrendX = (dc.getWidth() * 83) / 100;
        dc.drawText(etaValueX, distanceBottom + 8, Graphics.FONT_XTINY, "DIST. ETA", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(etaValueX, etaCenter + 3, Graphics.FONT_NUMBER_MEDIUM, _etaText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        drawEtaTrend(dc, etaTrendX, etaCenter);
        dc.drawLine(24, etaBottom, dc.getWidth() - 24, etaBottom);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(x, elevationCenter - 12, Graphics.FONT_NUMBER_THAI_HOT,
            ElevationUnits.fromMeters(_remainingElevationMeters).format("%.0f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, elevationCenter + 14, Graphics.FONT_SMALL, ElevationUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function progressColor(target as Lang.Numeric, remaining as Lang.Numeric) as Graphics.ColorType {
        if (target <= 0 || remaining <= 0) { return Graphics.COLOR_GREEN; }
        var completedFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        return completedFraction < 0.75 ? Graphics.COLOR_RED : Graphics.COLOR_WHITE;
    }

    private function etaColor(state as Lang.Symbol) as Graphics.ColorType {
        if (state == :ahead) { return Graphics.COLOR_GREEN; }
        if (state == :behind) { return Graphics.COLOR_RED; }
        return Graphics.COLOR_BLACK;
    }

    private function drawStatusRails(dc as Graphics.Dc, top as Lang.Number, bottom as Lang.Number,
            color as Graphics.ColorType) as Void {
        var railWidth = 6;
        dc.setColor(color, color);
        dc.fillRectangle(0, top, railWidth, bottom - top);
        dc.fillRectangle(dc.getWidth() - railWidth, top, railWidth, bottom - top);
    }

    function isBonusPromptVisible() as Lang.Boolean {
        return _distanceDisplayMode == :bonus_prompt;
    }

    function chooseBonusAt(x as Lang.Number) as Void {
        if (!isBonusPromptVisible()) { return; }
        var accepted = x < (_screenWidth / 2);
        _distanceDisplayMode = accepted ? :bonus : :complete;
        if (accepted) {
            _bonusRoundsAccepted += 1;
            _remainingMeters = GoalCalculator.bonusRemainingForRounds(
                _requiredTargetMeters, _completedTodayMeters,
                _bonusTargetMeters, _bonusRoundsAccepted);
            _distanceTargetMeters = _bonusTargetMeters;
        } else {
            _bonusOfferDeclined = true;
        }
        WatchUi.requestUpdate();
    }

    private function drawBonusPrompt(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = width / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(center, 22, Graphics.FONT_SMALL,
            _bonusRoundsAccepted == 0 ? "TODAY'S GOAL COMPLETE" : "BONUS GOAL COMPLETE",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, 66, Graphics.FONT_MEDIUM,
            "CHASE " + DistanceUnits.fromMeters(_bonusTargetMeters).format("%.0f") + " "
                + (_bonusRoundsAccepted == 0 ? "BONUS " : "MORE ")
                + DistanceUnits.label() + "?",
            Graphics.TEXT_JUSTIFY_CENTER);

        var buttonTop = (height * 58) / 100;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        dc.fillRectangle(8, buttonTop, (width / 2) - 12, height - buttonTop - 10);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle((width / 2) + 4, buttonTop, (width / 2) - 12, height - buttonTop - 10);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_GREEN);
        dc.drawText(width / 4, buttonTop + ((height - buttonTop) / 2) - 10,
            Graphics.FONT_LARGE, "YES", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.drawText((width * 3) / 4, buttonTop + ((height - buttonTop) / 2) - 10,
            Graphics.FONT_LARGE, "NO", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function updateRideLifecycle(info as Activity.Info) as Void {
        var distance = info.elapsedDistance == null ? -1.0 : info.elapsedDistance.toFloat();
        var timer = info.timerTime == null ? -1 : info.timerTime.toNumber();
        if ((_lastRideDistance >= 0 && distance >= 0 && distance < _lastRideDistance)
                || (_lastTimerTime >= 0 && timer >= 0 && timer < _lastTimerTime)) {
            _bonusRoundsAccepted = 0;
            _bonusOfferDeclined = false;
            _rideEnded = false;
            _sawActiveTimer = false;
            _lastDistanceFraction = -1.0;
            _distanceHalfwayAlerted = false;
        }
        _lastRideDistance = distance;
        _lastTimerTime = timer;

        if (info.timerState == Activity.TIMER_STATE_ON) {
            _sawActiveTimer = true;
        } else if (info.timerState == Activity.TIMER_STATE_STOPPED && _sawActiveTimer) {
            _rideEnded = true;
        }
    }

    private function updateDistanceMilestone(remaining as Lang.Numeric, target as Lang.Numeric) as Void {
        if (target <= 0) { return; }
        var fraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        if (_lastDistanceFraction >= 0 && _lastDistanceFraction < 0.5 && fraction >= 0.5
                && !_distanceHalfwayAlerted && GoalStore.alertEnabled(:halfway)) {
            if (WatchUi.DataField has :showAlert) {
                WatchUi.DataField.showAlert(new MilestoneAlertView(
                    "HALFWAY THERE",
                    DistanceUnits.fromMeters(remaining).format("%.1f") + " "
                        + DistanceUnits.label() + " REMAINING"));
            }
            if (GoalStore.alertEnabled(:sound) && (Attention has :playTone)) {
                Attention.playTone(Attention.TONE_DISTANCE_ALERT);
            }
            _distanceHalfwayAlerted = true;
        }
        _lastDistanceFraction = fraction;
    }

    private function drawEtaTrend(dc as Graphics.Dc, x as Lang.Number, centerY as Lang.Number) as Void {
        var iconX = x - 33;
        var textX = x + 7;
        if (_etaTrendState == :ahead) {
            drawTrendArrow(dc, iconX, centerY - 3, true);
            dc.drawText(textX, centerY - 13, Graphics.FONT_MEDIUM,
                _etaTrendMinutes.format("%02d") + " MIN", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL, "AHEAD", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_etaTrendState == :behind) {
            drawTrendArrow(dc, iconX, centerY - 3, false);
            dc.drawText(textX, centerY - 13, Graphics.FONT_MEDIUM,
                _etaTrendMinutes.format("%02d") + " MIN", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL, "BEHIND", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_etaTrendState == :on_pace) {
            drawPaceMarker(dc, iconX, centerY);
            dc.drawText(textX, centerY - 12, Graphics.FONT_MEDIUM, "ON", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL, "PACE", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x, centerY - 1, Graphics.FONT_SMALL, "MEASURING", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawPaceMarker(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number) as Void {
        dc.fillPolygon([
            [x, y - 9], [x + 3, y - 3], [x + 9, y], [x + 3, y + 3],
            [x, y + 9], [x - 3, y + 3], [x - 9, y], [x - 3, y - 3]
        ]);
    }

    private function drawTrendArrow(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
            pointsUp as Lang.Boolean) as Void {
        var points = pointsUp
            ? [[x, y - 6], [x - 8, y + 6], [x + 8, y + 6]]
            : [[x - 8, y - 6], [x + 8, y - 6], [x, y + 6]];
        dc.fillPolygon(points);
    }

}
