using Toybox.Activity;
using Toybox.Graphics;
using Toybox.WatchUi;

class CyclingGoalsView extends WatchUi.DataField {
    private var _remainingMiles as Float = 0.0;
    private var _configured as Boolean = false;

    function initialize() { DataField.initialize(); setLabel(Rez.Strings.FieldLabel); }

    function compute(info as Activity.Info) {
        _configured = GoalStore.hasGoals();
        if (!_configured) { return "SET GOALS"; }
        _remainingMiles = GoalCalculator.remainingForToday(info);
        return _remainingMiles;
    }

    function onUpdate(dc as Dc) as Void {
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
        dc.drawText(x, y - 10, Graphics.FONT_LARGE, _remainingMiles.format("%.1f"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y + 34, Graphics.FONT_SMALL, Rez.Strings.Miles, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
