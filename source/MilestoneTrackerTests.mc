using Toybox.Lang;

class MilestoneTrackerTests {
    (:test)
    static function catchesUpHalfwayOnFirstReading(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        return tracker.update(40, 100, true, true) == :halfway
            && tracker.halfwayAlerted;
    }

    (:test)
    static function completionSuppressesLaterHalfway(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        var first = tracker.update(0, 100, true, true);
        var second = tracker.update(40, 100, true, true);
        return first == :complete && second == :none
            && tracker.halfwayAlerted && tracker.completeAlerted;
    }

    (:test)
    static function disabledHalfwayCanBeCrossedWithoutAlert(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        var first = tracker.update(40, 100, false, true);
        var second = tracker.update(30, 100, true, true);
        return first == :none && second == :none && !tracker.halfwayAlerted;
    }

    (:test)
    static function disabledCompletionRemainsMissedAfterCrossing(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        var first = tracker.update(0, 100, true, false);
        var second = tracker.update(0, 100, true, true);
        return first == :halfway && second == :none && !tracker.completeAlerted;
    }

    (:test)
    static function resetRestoresFirstReadingCatchUp(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        tracker.update(0, 100, true, true);
        tracker.reset();
        return tracker.update(40, 100, true, true) == :halfway;
    }

    (:test)
    static function earlyFirstReadingDoesNotAlert(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        return tracker.update(60, 100, true, true) == :none;
    }

    (:test)
    static function halfwayDoesNotRepeat(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        var first = tracker.update(50, 100, true, true);
        var second = tracker.update(30, 100, true, true);
        return first == :halfway && second == :none;
    }

    (:test)
    static function completionDoesNotRepeat(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        var first = tracker.update(0, 100, true, true);
        var second = tracker.update(0, 100, true, true);
        return first == :complete && second == :none;
    }

    (:test)
    static function zeroTargetDoesNotAlert(logger) as Lang.Boolean {
        var tracker = new MilestoneTracker();
        return tracker.update(0, 0, true, true) == :none;
    }
}
