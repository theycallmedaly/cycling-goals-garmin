using Toybox.Graphics;
using Toybox.Math;
using Toybox.WatchUi;

class GoalSetupView extends WatchUi.View {
    private var _labels = ["YEARLY", "MONTHLY", "WEEKLY", "DAILY"];
    private var _steps = [100, 10, 5, 1];
    private var _goals as Array<Number>;
    private var _index as Number = 0;

    function initialize() { View.initialize(); _goals = GoalStore.getGoals(); }
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK); dc.clear();
        var x = dc.getWidth() / 2;
        dc.drawText(x, 14, Graphics.FONT_SMALL, "DISTANCE GOALS", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, 58, Graphics.FONT_MEDIUM, _labels[_index], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, dc.getHeight()/2 - 20, Graphics.FONT_LARGE, _goals[_index].format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, dc.getHeight()/2 + 28, Graphics.FONT_SMALL, "MILES", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, dc.getHeight()-48, Graphics.FONT_XTINY, "UP/DOWN TO CHANGE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, dc.getHeight()-24, Graphics.FONT_XTINY, _index == 3 ? "ENTER TO SAVE" : "ENTER FOR NEXT", Graphics.TEXT_JUSTIFY_CENTER);
    }
    function change(direction as Number) as Void {
        _goals[_index] = Math.max(0, _goals[_index] + (_steps[_index] * direction));
        WatchUi.requestUpdate();
    }
    function advance() as Boolean {
        if (_index < 3) { _index += 1; WatchUi.requestUpdate(); return false; }
        GoalStore.saveGoals(_goals); return true;
    }
}

