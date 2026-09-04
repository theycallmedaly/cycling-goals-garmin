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
    private var _etaTrend as EtaTrendEstimator;
    private var _etaText as Lang.String = "--H:--M";
    private var _etaTrendState as Lang.Symbol = :measuring;
    private var _etaTrendMinutes as Lang.Number = 0;
    private var _configured as Lang.Boolean = false;

    function initialize() {
        DataField.initialize();
        _recentPace = new RecentPaceEstimator();
        _etaTrend = new EtaTrendEstimator();
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
        var distanceStatus = progressColor(_distanceTargetMeters, _remainingMeters);
        var elevationStatus = progressColor(_elevationTargetMeters, _remainingElevationMeters);
        var etaBackground = etaColor(_etaTrendState);
        var distanceBottom = (dc.getHeight() * 37) / 100;
        var etaBottom = (dc.getHeight() * 63) / 100;
        var distanceBackground = Graphics.COLOR_BLACK;
        dc.setColor(distanceBackground, distanceBackground);
        dc.fillRectangle(0, 0, dc.getWidth(), distanceBottom);
        dc.setColor(etaBackground, etaBackground);
        dc.fillRectangle(0, distanceBottom, dc.getWidth(), etaBottom - distanceBottom);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0, etaBottom, dc.getWidth(), dc.getHeight() - etaBottom);

        drawStatusRails(dc, 0, distanceBottom, distanceStatus);
        drawStatusRails(dc, etaBottom, dc.getHeight(), elevationStatus);

        dc.setColor(Graphics.COLOR_WHITE, distanceBackground);
        dc.drawText(x, 4, Graphics.FONT_XTINY,
            Application.loadResource(Rez.Strings.RemainingToday), Graphics.TEXT_JUSTIFY_CENTER);
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
