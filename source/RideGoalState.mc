using Toybox.Lang;

// Owns the behavior-preserving transition between a required goal, the bonus
// offer, an accepted repeating bonus block, and the final complete state.
class RideGoalState {
    var displayMode as Lang.Symbol = :required;
    var remainingMeters as Lang.Float = 0.0;
    var displayTargetMeters as Lang.Float = 0.0;
    var requiredTargetMeters as Lang.Float = 0.0;
    var completedMeters as Lang.Float = 0.0;
    var bonusTargetMeters as Lang.Float = 0.0;
    var bonusProgressMeters as Lang.Float = 0.0;
    var bonusRoundsAccepted as Lang.Number = 0;
    var bonusOfferDeclined as Lang.Boolean = false;

    function update(requiredRemaining as Lang.Numeric, requiredTarget as Lang.Numeric,
            completed as Lang.Numeric, bonusTarget as Lang.Numeric,
            rideEnded as Lang.Boolean) as Void {
        remainingMeters = requiredRemaining.toFloat();
        displayTargetMeters = requiredTarget.toFloat();
        requiredTargetMeters = requiredTarget.toFloat();
        completedMeters = completed.toFloat();
        bonusTargetMeters = bonusTarget.toFloat();
        bonusProgressMeters = maximum(0.0, completedMeters - requiredTargetMeters);
        displayMode = :required;

        if (remainingMeters > 0 || bonusTargetMeters <= 0) { return; }
        if (rideEnded || bonusOfferDeclined) {
            displayMode = :complete;
            return;
        }

        var acceptedBonusMeters = bonusTargetMeters * bonusRoundsAccepted;
        if (bonusRoundsAccepted == 0 || bonusProgressMeters >= acceptedBonusMeters) {
            displayMode = :bonus_prompt;
            return;
        }

        displayMode = :bonus;
        remainingMeters = acceptedBonusMeters - bonusProgressMeters;
        displayTargetMeters = bonusTargetMeters;
    }

    function chooseBonus(accepted as Lang.Boolean) as Lang.Boolean {
        if (displayMode != :bonus_prompt) { return false; }
        if (accepted) {
            bonusRoundsAccepted += 1;
            displayMode = :bonus;
            remainingMeters = maximum(0.0,
                (bonusTargetMeters * bonusRoundsAccepted) - bonusProgressMeters);
            displayTargetMeters = bonusTargetMeters;
        } else {
            bonusOfferDeclined = true;
            displayMode = :complete;
        }
        return true;
    }

    function resetBonus() as Void {
        bonusRoundsAccepted = 0;
        bonusOfferDeclined = false;
    }

    private function maximum(a as Lang.Numeric, b as Lang.Numeric) as Lang.Float {
        return a > b ? a.toFloat() : b.toFloat();
    }
}
