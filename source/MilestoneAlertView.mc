using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class MilestoneAlertView extends WatchUi.DataFieldAlert {
    private var _title as Lang.String;
    private var _detail as Lang.String;

    function initialize(title as Lang.String, detail as Lang.String) {
        DataFieldAlert.initialize();
        _title = title;
        _detail = detail;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_GREEN);
        dc.clear();
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() * 34) / 100,
            Graphics.FONT_MEDIUM, _title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() * 55) / 100,
            Graphics.FONT_SMALL, _detail, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
