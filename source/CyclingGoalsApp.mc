using Toybox.Application;

class CyclingGoalsApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() {
        var view = new CyclingGoalsView();
        return [view, new CyclingGoalsInputDelegate(view)];
    }
    function getSettingsView() {
        var menu = SettingsView.createMenu();
        return [menu, new SettingsDelegate()];
    }
}
