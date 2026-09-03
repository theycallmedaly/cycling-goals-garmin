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

    private static function closeTo(actual as Lang.Numeric, expected as Lang.Numeric) as Lang.Boolean {
        var difference = actual.toFloat() - expected.toFloat();
        if (difference < 0) { difference = -difference; }
        return difference < 0.01;
    }
}
