using Toybox.Application;

class CyclingGoalsApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new CyclingGoalsView()]; }
    function getSettingsView() {
        var menu = GoalSetupView.createMenu();
        return [menu, new GoalSetupDelegate()];
    }
}
