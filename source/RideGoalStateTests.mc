using Toybox.Lang;

class RideGoalStateTests {
    (:test)
    static function incompleteRequiredGoalStaysRequired(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(40, 100, 60, 50, false);
        return state.displayMode == :required
            && closeTo(state.remainingMeters, 40)
            && closeTo(state.displayTargetMeters, 100);
    }

    (:test)
    static function completedRequiredGoalOffersBonus(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 110, 50, false);
        return state.displayMode == :bonus_prompt
            && closeTo(state.bonusProgressMeters, 10);
    }

    (:test)
    static function acceptedBonusCreditsRequiredGoalOvershoot(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 110, 50, false);
        state.chooseBonus(true);
        return state.displayMode == :bonus
            && state.bonusRoundsAccepted == 1
            && closeTo(state.remainingMeters, 40)
            && closeTo(state.displayTargetMeters, 50);
    }

    (:test)
    static function completedBonusRoundOffersAnotherBlock(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 100, 50, false);
        state.chooseBonus(true);
        state.update(0, 100, 150, 50, false);
        return state.displayMode == :bonus_prompt
            && state.bonusRoundsAccepted == 1;
    }

    (:test)
    static function declinedBonusStaysComplete(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 100, 50, false);
        state.chooseBonus(false);
        state.update(0, 100, 125, 50, false);
        return state.displayMode == :complete && state.bonusOfferDeclined;
    }

    (:test)
    static function endedRideDoesNotOfferBonus(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 100, 50, true);
        return state.displayMode == :complete;
    }

    (:test)
    static function resetAllowsBonusOfferAgain(logger) as Lang.Boolean {
        var state = new RideGoalState();
        state.update(0, 100, 100, 50, false);
        state.chooseBonus(false);
        state.resetBonus();
        state.update(0, 100, 100, 50, false);
        return state.displayMode == :bonus_prompt
            && state.bonusRoundsAccepted == 0
            && !state.bonusOfferDeclined;
    }

    private static function closeTo(actual as Lang.Numeric,
            expected as Lang.Numeric) as Lang.Boolean {
        var difference = actual.toFloat() - expected.toFloat();
        if (difference < 0) { difference = -difference; }
        return difference < 0.01;
    }
}
