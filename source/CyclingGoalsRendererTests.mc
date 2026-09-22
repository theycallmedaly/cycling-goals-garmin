using Toybox.Lang;

class CyclingGoalsRendererTests {
    (:test)
    static function currentDashIsTwiceBaseHeight(logger) as Lang.Boolean {
        var renderer = new CyclingGoalsRenderer();
        return renderer.progressDashHeight(1.0, 0.0, 2.0, 6) == 12;
    }

    (:test)
    static function completedDashReturnsToBaseHeight(logger) as Lang.Boolean {
        var renderer = new CyclingGoalsRenderer();
        return renderer.progressDashHeight(2.0, 0.0, 2.0, 6) == 6;
    }

    (:test)
    static function futureDashRemainsBaseHeight(logger) as Lang.Boolean {
        var renderer = new CyclingGoalsRenderer();
        return renderer.progressDashHeight(1.0, 2.0, 4.0, 6) == 6;
    }

    (:test)
    static function centerHalfUsesIndependentCurrentHeight(logger) as Lang.Boolean {
        var renderer = new CyclingGoalsRenderer();
        return renderer.progressDashHeight(6.5, 6.0, 7.0, 6) == 12
            && renderer.progressDashHeight(6.5, 7.0, 8.0, 6) == 6;
    }
}
