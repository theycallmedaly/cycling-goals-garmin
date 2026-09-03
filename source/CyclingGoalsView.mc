using Toybox.Activity;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsView extends WatchUi.DataField {
    private var _remainingMeters as Lang.Float = 0.0;
    private var _configured as Lang.Boolean = false;

    function initialize() { DataField.initialize(); }

    function compute(info as Activity.Info) {
        _configured = GoalStore.hasGoals();
        if (!_configured) { return "SET GOALS"; }
        _remainingMeters = GoalCalculator.remainingForToday(info);
        return DistanceUnits.fromMeters(_remainingMeters);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        if (!_configured) {
            dc.drawText(x, y - 18, Graphics.FONT_SMALL, Rez.Strings.NoGoals, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y + 10, Graphics.FONT_XTINY, Rez.Strings.OpenSettings, Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        dc.drawText(x, 8, Graphics.FONT_XTINY, Rez.Strings.RemainingToday, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y - 10, Graphics.FONT_LARGE, DistanceUnits.fromMeters(_remainingMeters).format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y + 34, Graphics.FONT_SMALL, DistanceUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
    }
}
