using Toybox.Activity;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsView extends WatchUi.DataField {
    private var _remainingMeters as Lang.Float = 0.0;
    private var _distanceTargetMeters as Lang.Float = 0.0;
    private var _remainingElevationMeters as Lang.Float = 0.0;
    private var _elevationTargetMeters as Lang.Float = 0.0;
    private var _recentPace as RecentPaceEstimator;
    private var _etaText as Lang.String = "--H:--M";
    private var _configured as Lang.Boolean = false;

    function initialize() {
        DataField.initialize();
        _recentPace = new RecentPaceEstimator();
    }

    function compute(info as Activity.Info) {
        _configured = GoalStore.hasGoals();
        if (!_configured) { return "SET GOALS"; }
        var distanceState = GoalCalculator.distanceStateForToday(info);
        _remainingMeters = distanceState[0];
        _distanceTargetMeters = distanceState[1];
        var elevationState = GoalCalculator.elevationStateForToday(info);
        _remainingElevationMeters = elevationState[0];
        _elevationTargetMeters = elevationState[1];
        if (info.elapsedDistance != null && info.timerTime != null) {
            var speed = _recentPace.update(info.elapsedDistance, info.timerTime, info.averageSpeed);
            _etaText = RecentPaceEstimator.formatEta(_remainingMeters, speed);
        } else {
            _etaText = RecentPaceEstimator.formatEta(_remainingMeters, info.averageSpeed);
        }
        return DistanceUnits.fromMeters(_remainingMeters);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
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
        var distanceBackground = progressColor(_distanceTargetMeters, _remainingMeters);
        var elevationBackground = progressColor(_elevationTargetMeters, _remainingElevationMeters);
        var distanceBottom = (dc.getHeight() * 37) / 100;
        var etaBottom = (dc.getHeight() * 63) / 100;
        dc.setColor(distanceBackground, distanceBackground);
        dc.fillRectangle(0, 0, dc.getWidth(), distanceBottom);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, distanceBottom, dc.getWidth(), etaBottom - distanceBottom);
        dc.setColor(elevationBackground, elevationBackground);
        dc.fillRectangle(0, etaBottom, dc.getWidth(), dc.getHeight() - etaBottom);

        dc.setColor(Graphics.COLOR_WHITE, distanceBackground);
        dc.drawText(x, 4, Graphics.FONT_XTINY,
            Application.loadResource(Rez.Strings.RemainingToday), Graphics.TEXT_JUSTIFY_CENTER);
        var distanceCenter = (24 + distanceBottom) / 2;
        var etaCenter = distanceBottom + ((etaBottom - distanceBottom) / 2);
        var elevationCenter = etaBottom + ((dc.getHeight() - etaBottom) / 2);

        dc.drawText(x, distanceCenter - 4, Graphics.FONT_NUMBER_HOT,
            DistanceUnits.fromMeters(_remainingMeters).format("%.2f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, distanceCenter + 34, Graphics.FONT_SMALL, DistanceUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawLine(24, distanceBottom, dc.getWidth() - 24, distanceBottom);
        dc.drawText(x, etaCenter - 8, Graphics.FONT_LARGE, _etaText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, etaCenter + 20, Graphics.FONT_SMALL, "DIST. ETA", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawLine(24, etaBottom, dc.getWidth() - 24, etaBottom);

        dc.setColor(Graphics.COLOR_WHITE, elevationBackground);
        dc.drawText(x, elevationCenter - 4, Graphics.FONT_NUMBER_HOT,
            ElevationUnits.fromMeters(_remainingElevationMeters).format("%.0f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, elevationCenter + 34, Graphics.FONT_SMALL, ElevationUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function progressColor(target as Lang.Numeric, remaining as Lang.Numeric) as Graphics.ColorType {
        if (target <= 0 || remaining <= 0) { return Graphics.COLOR_GREEN; }
        var completedFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        return completedFraction < 0.75 ? Graphics.COLOR_RED : Graphics.COLOR_BLACK;
    }
}
