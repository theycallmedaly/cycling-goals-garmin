using Toybox.Lang;
using Toybox.WatchUi;

class GoalSetupDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() { Menu2InputDelegate.initialize(); }
    function onSelect(item as WatchUi.MenuItem) as Void {
        var view = new GoalEditView(item.getId() as Lang.Symbol);
        WatchUi.pushView(view, new GoalEditDelegate(view), WatchUi.SLIDE_UP);
    }
}

class GoalEditDelegate extends WatchUi.BehaviorDelegate {
    private var _view as GoalEditView;
    function initialize(view as GoalEditView) { BehaviorDelegate.initialize(); _view = view; }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        return _view.handleTap(event.getCoordinates());
    }

    function onHold(event as WatchUi.ClickEvent) as Lang.Boolean {
        return _view.handleHold(event.getCoordinates());
    }
}
