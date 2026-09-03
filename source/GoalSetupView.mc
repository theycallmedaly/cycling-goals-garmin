using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

class GoalSetupView {
    static function createMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title=>"UPDATE GOALS"});
        menu.addItem(new WatchUi.MenuItem("Daily", "Auto or override", :daily, {}));
        menu.addItem(new WatchUi.MenuItem("Weekly", null, :weekly, {}));
        menu.addItem(new WatchUi.MenuItem("Monthly", null, :monthly, {}));
        menu.addItem(new WatchUi.MenuItem("Yearly", null, :yearly, {}));
        return menu;
    }
}

class GoalEditView extends WatchUi.View {
    private var _kind as Lang.Symbol;
    private var _value as Lang.Number;
    private var _original as Lang.Number;
    private var _width as Lang.Number = 240;
    private var _height as Lang.Number = 320;

    function initialize(kind as Lang.Symbol) {
        View.initialize();
        _kind = kind;
        _value = loadDisplayValue();
        _original = _value;
    }

    function onUpdate(dc) {
        _width = dc.getWidth();
        _height = dc.getHeight();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var title = _kind.toString().toUpper() + " DISTANCE";
        dc.drawText(x, 18, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, 70, Graphics.FONT_LARGE,
            (_kind == :daily && _value == 0) ? "AUTO" : _value.format("%d") + " " + DistanceUnits.label(),
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x - 55, 150, Graphics.FONT_LARGE, "▲", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x + 55, 150, Graphics.FONT_LARGE, "▼", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawRectangle(12, dc.getHeight()-55, (dc.getWidth()/2)-18, 42);
        dc.drawRectangle((dc.getWidth()/2)+6, dc.getHeight()-55, (dc.getWidth()/2)-18, 42);
        dc.drawText(dc.getWidth()/4, dc.getHeight()-45, Graphics.FONT_SMALL, "SAVE", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText((dc.getWidth()*3)/4, dc.getHeight()-45, Graphics.FONT_SMALL, "CANCEL", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function change(direction as Lang.Number) {
        var step = stepSize();
        _value = maximum(0, _value + (direction * step));
        WatchUi.requestUpdate();
    }

    function save() {
        var goals = GoalStore.getGoals();
        if (_kind == :yearly) { goals[0] = DistanceUnits.toMeters(_value); }
        else if (_kind == :monthly) { goals[1] = DistanceUnits.toMeters(_value); }
        else if (_kind == :weekly) { goals[2] = DistanceUnits.toMeters(_value); }
        else {
            GoalStore.saveDailyOverride(todayKey(), _value == 0 ? null : DistanceUnits.toMeters(_value));
        }
        if (_kind != :daily) { GoalStore.saveGoals(goals); }
    }

    function restore() { _value = _original; }

    function handleTap(point as Lang.Array<Lang.Number>) as Lang.Boolean {
        if (point[1] >= 105 && point[1] <= (_height - 70)) {
            change(point[0] < _width/2 ? 1 : -1);
            return true;
        }
        if (point[1] >= (_height - 65)) {
            if (point[0] < _width/2) { save(); }
            else { restore(); }
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        return false;
    }

    private function loadDisplayValue() as Lang.Number {
        var goals = GoalStore.getGoals();
        var meters;
        if (_kind == :yearly) { meters = goals[0]; }
        else if (_kind == :monthly) { meters = goals[1]; }
        else if (_kind == :weekly) { meters = goals[2]; }
        else { meters = GoalStore.getDailyOverride(todayKey()); }
        return meters == null ? 0 : DistanceUnits.fromMeters(meters).toNumber();
    }

    private function stepSize() as Lang.Number {
        if (_kind == :yearly) { return 100; }
        if (_kind == :monthly) { return 10; }
        if (_kind == :weekly) { return 5; }
        return 1;
    }

    private function maximum(a as Lang.Number, b as Lang.Number) as Lang.Number {
        return a > b ? a : b;
    }

    private function todayKey() as Lang.Number {
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (date.year * 10000) + (date.month * 100) + date.day;
    }
}
