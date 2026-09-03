using Toybox.Math;
using Toybox.Test;

class GoalCalculatorTests {
    const MILE = 1609.344;

    (:test)
    static function saturdayActiveRide(logger) as Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 0, 0, 10,
            215*MILE, 157.3*MILE, 2, false, false);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 24*MILE) / MILE;
        logger.debug("S1 remaining miles: " + result);
        return closeTo(result, 4.85);
    }

    (:test)
    static function sundayWeeklyCloseout(logger) as Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*MILE, 999*MILE, 2,
            215*MILE, 20*MILE, 1, true, true);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 0) / MILE;
        logger.debug("S2 remaining miles: " + result);
        return closeTo(result, 195.0);
    }

    (:test)
    static function mondayLongRide(logger) as Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*MILE, 0, 20,
            215*MILE, 0, 7, false, false);
        var result = GoalCalculator.remainingAfterProgress(target, 0, 100*MILE) / MILE;
        logger.debug("S3 remaining miles: " + result);
        return closeTo(result, 0.0);
    }

    (:test)
    static function sundayUsesLargerMonthRemainder(logger) as Boolean {
        var target = GoalCalculator.calculateAutomaticGoal(
            0, 0, 100, 1000*MILE, 979*MILE, 2,
            215*MILE, 195*MILE, 1, true, true);
        logger.debug("Month-end target miles: " + (target/MILE));
        return closeTo(target/MILE, 21.0);
    }

    private static function closeTo(actual as Numeric, expected as Numeric) as Boolean {
        return Math.abs(actual.toFloat() - expected.toFloat()) < 0.01;
    }
}
