using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class MilestoneAlertView extends WatchUi.DataFieldAlert {
    private var _title as Lang.String;
    private var _detail as Lang.String;
    private var _iconKind as Lang.Symbol;

    function initialize(title as Lang.String, detail as Lang.String, iconKind as Lang.Symbol) {
        DataFieldAlert.initialize();
        _title = title;
        _detail = detail;
        _iconKind = iconKind;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.clear();

        var centerX = dc.getWidth() / 2;
        if (_iconKind == :elevation) {
            drawElevationIcon(dc, centerX);
        } else {
            drawDistanceIcon(dc, centerX);
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.drawText(centerX, 96,
            Graphics.FONT_SYSTEM_LARGE, _title, Graphics.TEXT_JUSTIFY_CENTER);

        var separator = _detail.find(" ");
        var value = separator == null ? _detail : _detail.substring(0, separator);
        var label = separator == null ? "" : _detail.substring(separator + 1, _detail.length());
        dc.drawText(centerX, 132,
            Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, value, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 214,
            Graphics.FONT_SYSTEM_LARGE, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawDistanceIcon(dc as Graphics.Dc, centerX as Lang.Number) as Void {
        var flagTop = 18;
        var courseY = 68;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(4);
        dc.drawLine(centerX, flagTop, centerX, courseY);
        dc.drawLine(centerX - 42, courseY, centerX + 42, courseY);
        dc.fillCircle(centerX - 42, courseY, 4);
        dc.fillCircle(centerX, courseY, 7);
        dc.fillCircle(centerX + 42, courseY, 4);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_DK_GRAY);
        dc.fillPolygon([
            [centerX + 3, flagTop + 3],
            [centerX + 34, flagTop + 15],
            [centerX + 3, flagTop + 28]
        ]);
    }

    private function drawElevationIcon(dc as Graphics.Dc, centerX as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.setPenWidth(4);
        dc.drawLine(centerX - 48, 70, centerX - 10, 23);
        dc.drawLine(centerX - 10, 23, centerX + 8, 49);
        dc.drawLine(centerX + 8, 49, centerX + 27, 31);
        dc.drawLine(centerX + 27, 31, centerX + 48, 70);

        var flagX = centerX - 40;
        dc.drawLine(flagX, 33, flagX, 60);
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_DK_GRAY);
        dc.fillPolygon([
            [flagX - 2, 33],
            [flagX - 20, 39],
            [flagX - 2, 45]
        ]);
    }
}
