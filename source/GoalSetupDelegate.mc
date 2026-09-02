using Toybox.WatchUi;

class GoalSetupDelegate extends WatchUi.InputDelegate {
    private var _view as GoalSetupView;
    function initialize(view as GoalSetupView) { InputDelegate.initialize(); _view = view; }
    function onKey(event as KeyEvent) as Boolean {
        var key = event.getKey();
        if (key == WatchUi.KEY_UP) { _view.change(1); return true; }
        if (key == WatchUi.KEY_DOWN) { _view.change(-1); return true; }
        if (key == WatchUi.KEY_ENTER) {
            if (_view.advance()) { WatchUi.popView(WatchUi.SLIDE_DOWN); }
            return true;
        }
        return false;
    }
}

