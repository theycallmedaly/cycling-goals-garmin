using Toybox.Lang;
using Toybox.Test;
using Toybox.Time.Gregorian;

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

    (:test)
    static function etaTrendMeasuresForFifteenMinutes(logger) as Lang.Boolean {
        var estimator = new EtaTrendEstimator();
        var result = estimator.update(0, 3600, 1.0);
        return result[0] == :measuring;
    }

    (:test)
    static function etaTrendRecognizesOnPace(logger) as Lang.Boolean {
        var estimator = new EtaTrendEstimator();
        estimator.update(0, 3600, 1.0);
        var result = estimator.update(900000, 2700, 1.0);
        return result[0] == :on_pace;
    }

    (:test)
    static function etaTrendRecognizesTenMinutesAhead(logger) as Lang.Boolean {
        var estimator = new EtaTrendEstimator();
        estimator.update(0, 3600, 1.0);
        var result = estimator.update(900000, 2100, 1.0);
        return result[0] == :ahead && result[1] == 10;
    }

    (:test)
    static function etaTrendRecognizesTenMinutesBehind(logger) as Lang.Boolean {
        var estimator = new EtaTrendEstimator();
        estimator.update(0, 3600, 1.0);
        var result = estimator.update(900000, 3300, 1.0);
        return result[0] == :behind && result[1] == 10;
    }

    (:test)
    static function automaticBonusIsHalfOfAutomaticDailyGoal(logger) as Lang.Boolean {
        return closeTo(GoalCalculator.bonusTarget(30 * TEST_MILE, null) / TEST_MILE, 15.0);
    }

    (:test)
    static function configuredBonusOverridesAutomaticBonus(logger) as Lang.Boolean {
        return closeTo(GoalCalculator.bonusTarget(30 * TEST_MILE, 20 * TEST_MILE) / TEST_MILE, 20.0);
    }

    (:test)
    static function automaticElevationBonusRepeatsDailyGoal(logger) as Lang.Boolean {
        return closeTo(GoalCalculator.elevationBonusTarget(1370, null), 1370);
    }

    (:test)
    static function customElevationBonusOverridesDailyGoal(logger) as Lang.Boolean {
        return closeTo(GoalCalculator.elevationBonusTarget(1370, 2000), 2000);
    }

    (:test)
    static function requiredGoalOvershootCountsTowardBonus(logger) as Lang.Boolean {
        var result = GoalCalculator.bonusRemaining(30 * TEST_MILE, 36.5 * TEST_MILE, 15 * TEST_MILE);
        return closeTo(result / TEST_MILE, 8.5);
    }

    (:test)
    static function secondBonusExtendsFirstBonus(logger) as Lang.Boolean {
        var result = GoalCalculator.bonusRemainingForRounds(
            30 * TEST_MILE, 45 * TEST_MILE, 15 * TEST_MILE, 2);
        return closeTo(result / TEST_MILE, 15.0);
    }

    (:test)
    static function overshootCarriesIntoSecondBonus(logger) as Lang.Boolean {
        var result = GoalCalculator.bonusRemainingForRounds(
            30 * TEST_MILE, 47 * TEST_MILE, 15 * TEST_MILE, 2);
        return closeTo(result / TEST_MILE, 13.0);
    }

    (:test)
    static function acceptedBonusRoundCompletesAtThreshold(logger) as Lang.Boolean {
        return GoalCalculator.bonusRoundCompleted(15 * TEST_MILE, 15 * TEST_MILE, 1, 0);
    }

    (:test)
    static function bonusRoundDoesNotAlertBeforeThreshold(logger) as Lang.Boolean {
        return !GoalCalculator.bonusRoundCompleted(14.9 * TEST_MILE, 15 * TEST_MILE, 1, 0);
    }

    (:test)
    static function bonusRoundAlertDoesNotRepeat(logger) as Lang.Boolean {
        return !GoalCalculator.bonusRoundCompleted(15 * TEST_MILE, 15 * TEST_MILE, 1, 1);
    }

    (:test)
    static function eachAcceptedBonusRoundCanAlert(logger) as Lang.Boolean {
        return GoalCalculator.bonusRoundCompleted(30 * TEST_MILE, 15 * TEST_MILE, 2, 1);
    }

    (:test)
    static function halfwayTriggersOnCrossing(logger) as Lang.Boolean {
        return GoalCalculator.crossedHalfway(0.49, 500, 1000);
    }

    (:test)
    static function halfwayCatchesUpOnFirstSample(logger) as Lang.Boolean {
        return GoalCalculator.crossedHalfway(-1.0, 400, 1000);
    }

    (:test)
    static function halfwayDoesNotTriggerOnEarlyFirstSample(logger) as Lang.Boolean {
        return !GoalCalculator.crossedHalfway(-1.0, 600, 1000);
    }

    (:test)
    static function halfwayDoesNotRepeatAfterCrossing(logger) as Lang.Boolean {
        return !GoalCalculator.crossedHalfway(0.5, 300, 1000);
    }

    (:test)
    static function halfwayIgnoresDisabledGoal(logger) as Lang.Boolean {
        return !GoalCalculator.crossedHalfway(0.49, 0, 0);
    }

    (:test)
    static function goalCompleteTriggersOnCrossing(logger) as Lang.Boolean {
        return GoalCalculator.crossedGoal(0.99, 0, 1000);
    }

    (:test)
    static function goalCompleteCatchesUpOnFirstSample(logger) as Lang.Boolean {
        return GoalCalculator.crossedGoal(-1.0, 0, 1000);
    }

    (:test)
    static function goalCompleteDoesNotTriggerOnEarlyFirstSample(logger) as Lang.Boolean {
        return !GoalCalculator.crossedGoal(-1.0, 1, 1000);
    }

    (:test)
    static function goalCompleteDoesNotRepeat(logger) as Lang.Boolean {
        return !GoalCalculator.crossedGoal(1.0, 0, 1000);
    }

    (:test)
    static function goalCompleteIgnoresDisabledGoal(logger) as Lang.Boolean {
        return !GoalCalculator.crossedGoal(0.99, 0, 0);
    }

    (:test)
    static function allAlertsCascadesToIndividualSettings(logger) as Lang.Boolean {
        GoalStore.saveAlertSetting(:all_alerts, false);
        var settings = GoalStore.individualAlertSettings();
        var disabled = true;
        for (var i = 0; i < settings.size(); i += 1) {
            disabled = disabled && !GoalStore.alertSetting(settings[i]);
        }

        GoalStore.saveAlertSetting(:all_alerts, true);
        var enabled = true;
        for (var j = 0; j < settings.size(); j += 1) {
            enabled = enabled && GoalStore.alertSetting(settings[j]);
        }
        return disabled && enabled;
    }

    (:test)
    static function mondayWeekStartsOnMonday(logger) as Lang.Boolean {
        return GoalCalculator.daysSinceConfiguredWeekStart(
            Gregorian.DAY_MONDAY, Gregorian.DAY_MONDAY) == 0;
    }

    (:test)
    static function sundayEndsMondayBasedWeek(logger) as Lang.Boolean {
        return GoalCalculator.isLastDayOfConfiguredWeek(
            Gregorian.DAY_SUNDAY, Gregorian.DAY_MONDAY);
    }

    (:test)
    static function saturdayEndsSundayBasedWeek(logger) as Lang.Boolean {
        return GoalCalculator.isLastDayOfConfiguredWeek(
            Gregorian.DAY_SATURDAY, Gregorian.DAY_SUNDAY);
    }

    (:test)
    static function sundayStartsSundayBasedWeek(logger) as Lang.Boolean {
        return GoalCalculator.daysRemainingInConfiguredWeek(
            Gregorian.DAY_SUNDAY, Gregorian.DAY_SUNDAY) == 7;
    }

    (:test)
    static function oneRestWeekdayLeavesFourWeekdayRideSlots(logger) as Lang.Boolean {
        var counts = GoalCalculator.scheduleCounts(
            Gregorian.DAY_MONDAY, 7, 1, 1, 0);
        return counts[0] == 4 && counts[1] == 1 && counts[2] == 1;
    }

    (:test)
    static function elapsedRestDayDoesNotConsumeRideSlot(logger) as Lang.Boolean {
        var counts = GoalCalculator.scheduleCounts(
            Gregorian.DAY_TUESDAY, 6, 1, 1, 0);
        return counts[0] == 4;
    }

    (:test)
    static function elapsedRideDayConsumesRideSlot(logger) as Lang.Boolean {
        var counts = GoalCalculator.scheduleCounts(
            Gregorian.DAY_TUESDAY, 6, 1, 1, 1);
        return counts[0] == 3;
    }

    (:test)
    static function fiveRestWeekdaysExcludeWeekdayTargets(logger) as Lang.Boolean {
        var counts = GoalCalculator.scheduleCounts(
            Gregorian.DAY_MONDAY, 7, 5, 1, 0);
        var target = GoalCalculator.scheduledPeriodTarget(
            100 * TEST_MILE, counts, true, false,
            DEFAULT_LONG_DAY_DISTANCE_METERS, null);
        return counts[0] == 0 && closeTo(target[0], 0);
    }

    (:test)
    static function restDayCapacityRedistributesWeekdayWork(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledPeriodTarget(
            100 * TEST_MILE, [4, 0, 0], true, false,
            DEFAULT_LONG_DAY_DISTANCE_METERS, null);
        return closeTo(target[0] / TEST_MILE, 25.0);
    }

    (:test)
    static function saturdayIsFirstLongDay(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledPeriodTarget(
            100 * TEST_MILE, [4, 1, 1], false, true,
            DEFAULT_LONG_DAY_DISTANCE_METERS, null);
        return closeTo(target[0] / TEST_MILE, 75.0);
    }

    (:test)
    static function weekdayDistanceLimitIsMarkedAndApplied(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledPeriodTarget(
            275 * TEST_MILE, [4, 1, 1], true, false,
            DEFAULT_LONG_DAY_DISTANCE_METERS, 25 * TEST_MILE);
        return closeTo(target[0] / TEST_MILE, 25.0) && target[1] == 1.0;
    }

    (:test)
    static function weekdayDistanceLimitMovesWorkToWeekend(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledPeriodTarget(
            275 * TEST_MILE, [4, 1, 1], false, true,
            DEFAULT_LONG_DAY_DISTANCE_METERS, 25 * TEST_MILE);
        return closeTo(target[0] / TEST_MILE, 87.5) && target[1] == 0.0;
    }

    (:test)
    static function restWeekdayCapacityRaisesElevationTarget(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledElevationTarget(
            20, Gregorian.DAY_MONDAY, 1, 1,
            DEFAULT_LONG_DAY_ELEVATION_METERS, null);
        return closeTo(target[0], 25.0);
    }

    (:test)
    static function weekdayElevationLimitIsMarkedAndApplied(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledElevationTarget(
            2000, Gregorian.DAY_MONDAY, 1, 1,
            DEFAULT_LONG_DAY_ELEVATION_METERS, 2100);
        return closeTo(target[0], 2100) && target[1] == 1.0;
    }

    (:test)
    static function saturdayUsesLongDayElevation(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledElevationTarget(
            100, Gregorian.DAY_SATURDAY, 1, 1,
            DEFAULT_LONG_DAY_ELEVATION_METERS, null);
        return closeTo(target[0], DEFAULT_LONG_DAY_ELEVATION_METERS);
    }

    (:test)
    static function usedWeekdayRideSlotsMakeRemainingWeekdayRest(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateScheduledAutomaticGoal(
            100 * TEST_MILE, 0, 100,
            100 * TEST_MILE, 0, 20,
            100 * TEST_MILE, 0, 3,
            false, false, Gregorian.DAY_FRIDAY, 1, 1,
            DEFAULT_LONG_DAY_DISTANCE_METERS, 4, null);
        return closeTo(target[0], 0) && target[2] == 0.0;
    }

    (:test)
    static function allRestWeekdaysLeaveWeekendCalculationActive(logger) as Lang.Boolean {
        var target = GoalCalculator.calculateScheduledAutomaticGoal(
            100 * TEST_MILE, 0, 2,
            100 * TEST_MILE, 0, 2,
            100 * TEST_MILE, 0, 2,
            false, true, Gregorian.DAY_SATURDAY, 5, 1,
            DEFAULT_LONG_DAY_DISTANCE_METERS, 0, null);
        return closeTo(target[0] / TEST_MILE, 75.0) && target[2] == 1.0;
    }

    (:test)
    static function customLongDayDistanceChangesSaturdayTarget(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledPeriodTarget(
            100 * TEST_MILE, [4, 1, 1], false, true,
            60 * TEST_MILE, null);
        return closeTo(target[0] / TEST_MILE, 60.0);
    }

    (:test)
    static function customLongDayElevationChangesSaturdayTarget(logger) as Lang.Boolean {
        var target = GoalCalculator.scheduledElevationTarget(
            100, Gregorian.DAY_SATURDAY, 1, 1, 7000, null);
        return closeTo(target[0], 7000);
    }

    private static function closeTo(actual as Lang.Numeric, expected as Lang.Numeric) as Lang.Boolean {
        var difference = actual.toFloat() - expected.toFloat();
        if (difference < 0) { difference = -difference; }
        return difference < 0.01;
    }
}
