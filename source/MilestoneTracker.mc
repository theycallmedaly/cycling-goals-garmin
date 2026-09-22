using Toybox.Lang;

class MilestoneTracker {
    var lastFraction as Lang.Float = -1.0;
    var halfwayAlerted as Lang.Boolean = false;
    var completeAlerted as Lang.Boolean = false;

    function update(remaining as Lang.Numeric, target as Lang.Numeric,
            halfwayEnabled as Lang.Boolean, completeEnabled as Lang.Boolean) as Lang.Symbol {
        if (target <= 0) { return :none; }
        var fraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        var event = :none;
        if (crossed(lastFraction, fraction, 1.0)
                && !completeAlerted && completeEnabled) {
            completeAlerted = true;
            halfwayAlerted = true;
            event = :complete;
        } else if (crossed(lastFraction, fraction, 0.5)
                && !halfwayAlerted && halfwayEnabled) {
            halfwayAlerted = true;
            event = :halfway;
        }
        lastFraction = fraction;
        return event;
    }

    function reset() as Void {
        lastFraction = -1.0;
        halfwayAlerted = false;
        completeAlerted = false;
    }

    private function crossed(previousFraction as Lang.Numeric,
            currentFraction as Lang.Numeric, threshold as Lang.Numeric) as Lang.Boolean {
        return previousFraction < threshold && currentFraction >= threshold;
    }
}
