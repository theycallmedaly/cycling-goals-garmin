using Toybox.Lang;
using Toybox.Test;

const TEST_MILE = 1609.344;

class GoalCalculatorTests {
    (:test)
    static function saturdayActiveRide(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 0, 0, 10,
            215*TEST_MILE, 157.3*TEST_MILE, 2, false, false);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 24*TEST_MILE) / TEST_MILE;
        logger.debug("S1 remaining miles: " + result);
        return closeTo(result, 4.85);
    }

    (:test)
    static function sundayWeeklyCloseout(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*TEST_MILE, 999*TEST_MILE, 2,
            215*TEST_MILE, 20*TEST_MILE, 1, true, true);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 0) / TEST_MILE;
        logger.debug("S2 remaining miles: " + result);
        return closeTo(result, 195.0);
    }

    (:test)
    static function mondayLongRide(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*TEST_MILE, 0, 20,
            215*TEST_MILE, 0, 7, false, false);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 100*TEST_MILE) / TEST_MILE;
        logger.debug("S3 remaining miles: " + result);
        return closeTo(result, 0.0);
    }

    (:test)
    static function sundayUsesLargerMonthRemainder(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*TEST_MILE, 979*TEST_MILE, 2,
            215*TEST_MILE, 195*TEST_MILE, 1, true, true);
        logger.debug("Month-end target miles: " + (target/TEST_MILE));
        return closeTo(target/TEST_MILE, 21.0);
    }

    (:test)
    static function etaRoundsToNearestMinute(logger) as Lang.Boolean {
        var speed = 15.3 * TEST_MILE / 3600.0;
        var result = RecentPaceEstimator.formatEta(12.4 * TEST_MILE, speed);
        logger.debug("Distance ETA: " + result);
        return result.equals("00H:49M");
    }

    (:test)
    static function etaUnavailableWithoutSpeed(logger) as Lang.Boolean {
        return RecentPaceEstimator.formatEta(12.4 * TEST_MILE, null).equals("--H:--M");
    }

    (:test)
    static function recentPaceFallsBackBeforeFiveMiles(logger) as Lang.Boolean {
        var estimator = new RecentPaceEstimator();
        var fallback = 15.3 * TEST_MILE / 3600.0;
        var result = estimator.update(0, 0, fallback);
        result = estimator.update(4.9 * TEST_MILE, 1152941, fallback);
        return closeTo(result, fallback);
    }

    (:test)
    static function recentPaceUsesFiveMileWindow(logger) as Lang.Boolean {
        var estimator = new RecentPaceEstimator();
        var fallback = 10.0 * TEST_MILE / 3600.0;
        estimator.update(0, 0, fallback);
        var result = estimator.update(5.0 * TEST_MILE, 1176471, fallback);
        var expected = 15.3 * TEST_MILE / 3600.0;
        return closeTo(result, expected);
    }

    (:test)
    static function recentPaceExcludesPausedTime(logger) as Lang.Boolean {
        var estimator = new RecentPaceEstimator();
        var fallback = 10.0 * TEST_MILE / 3600.0;
        estimator.update(0, 0, fallback);
        estimator.update(2.0 * TEST_MILE, 470588, fallback);
        // A pause does not advance distance or Garmin's recording timer.
        estimator.update(2.0 * TEST_MILE, 470588, fallback);
        var result = estimator.update(5.0 * TEST_MILE, 1176471, fallback);
        var expected = 15.3 * TEST_MILE / 3600.0;
        return closeTo(result, expected);
    }

    private static function closeTo(actual as Lang.Numeric, expected as Lang.Numeric) as Lang.Boolean {
        var difference = actual.toFloat() - expected.toFloat();
        if (difference < 0) { difference = -difference; }
        return difference < 0.01;
    }
}
