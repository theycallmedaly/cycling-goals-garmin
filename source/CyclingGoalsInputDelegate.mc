using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsInputDelegate extends WatchUi.InputDelegate {
    private var _view as CyclingGoalsView;

    function initialize(view as CyclingGoalsView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onTap(event as WatchUi.ClickEvent) as Lang.Boolean {
        if (!_view.isBonusPromptVisible()) { return false; }
        var coordinates = event.getCoordinates();
        _view.chooseBonusAt(coordinates[0]);
        return true;
    }
}
