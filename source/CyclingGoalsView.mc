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
    private var _configured as Lang.Boolean = false;

    function initialize() { DataField.initialize(); }

    function compute(info as Activity.Info) {
        _configured = GoalStore.hasGoals();
        if (!_configured) { return "SET GOALS"; }
        var distanceState = GoalCalculator.distanceStateForToday(info);
        _remainingMeters = distanceState[0];
        _distanceTargetMeters = distanceState[1];
        var elevationState = GoalCalculator.elevationStateForToday(info);
        _remainingElevationMeters = elevationState[0];
        _elevationTargetMeters = elevationState[1];
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
        var distanceBackground = progressColor(_distanceTargetMeters, _remainingMeters, true);
        var elevationBackground = progressColor(_elevationTargetMeters, _remainingElevationMeters, false);
        dc.setColor(distanceBackground, distanceBackground);
        dc.fillRectangle(0, 0, dc.getWidth(), y);
        dc.setColor(elevationBackground, elevationBackground);
        dc.fillRectangle(0, y, dc.getWidth(), dc.getHeight() - y);

        dc.setColor(Graphics.COLOR_WHITE, distanceBackground);
        dc.drawText(x, 8, Graphics.FONT_XTINY,
            Application.loadResource(Rez.Strings.RemainingToday), Graphics.TEXT_JUSTIFY_CENTER);
        var dividerY = y;
        var upperCenter = (28 + dividerY) / 2;
        var lowerCenter = dividerY + ((dc.getHeight() - dividerY) / 2);

        dc.drawText(x, upperCenter - 8, Graphics.FONT_NUMBER_HOT,
            DistanceUnits.fromMeters(_remainingMeters).format("%.2f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, upperCenter + 33, Graphics.FONT_SMALL, DistanceUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawLine(24, dividerY, dc.getWidth() - 24, dividerY);

        dc.setColor(Graphics.COLOR_WHITE, elevationBackground);
        dc.drawText(x, lowerCenter - 8, Graphics.FONT_NUMBER_HOT,
            ElevationUnits.fromMeters(_remainingElevationMeters).format("%.0f"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, lowerCenter + 33, Graphics.FONT_SMALL, ElevationUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function progressColor(target as Lang.Numeric, remaining as Lang.Numeric,
            useBrightRed as Lang.Boolean) as Graphics.ColorType {
        if (target <= 0 || remaining <= 0) {
            return Graphics.createColor(255, 71, 122, 72);
        }
        var completedFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        return completedFraction < 0.75
            ? (useBrightRed ? Graphics.COLOR_RED : Graphics.createColor(255, 155, 58, 50))
            : Graphics.COLOR_BLACK;
    }
}
