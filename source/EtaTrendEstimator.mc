using Toybox.Lang;

const ETA_TREND_WINDOW_MS = 900000;
const ETA_TREND_SAMPLE_MS = 60000;
const ETA_TREND_TOLERANCE_MS = 60000;

class EtaTrendEstimator {
    private var _timerTimes as Lang.Array<Lang.Number>;
    private var _projectedFinishTimes as Lang.Array<Lang.Number>;

    function initialize() {
        _timerTimes = [];
        _projectedFinishTimes = [];
    }

    // Returns [state, minutes], where state is :measuring, :ahead, :on_pace, or :behind.
    function update(timerMilliseconds as Lang.Numeric, remainingMeters as Lang.Numeric,
            speedMps as Lang.Numeric or Null) as Lang.Array {
        if (speedMps == null || speedMps <= 0) { return [:measuring, 0]; }

        var timer = timerMilliseconds.toNumber();
        if (_timerTimes.size() > 0 && timer < _timerTimes[_timerTimes.size() - 1]) { reset(); }

        var projected = timer + ((remainingMeters.toFloat() / speedMps.toFloat()) * 1000.0).toNumber();
        if (_timerTimes.size() == 0
                || timer - _timerTimes[_timerTimes.size() - 1] >= ETA_TREND_SAMPLE_MS) {
            _timerTimes.add(timer);
            _projectedFinishTimes.add(projected);
        }

        var comparisonIndex = -1;
        for (var i = _timerTimes.size() - 1; i >= 0; i -= 1) {
            if (timer - _timerTimes[i] >= ETA_TREND_WINDOW_MS) {
                comparisonIndex = i;
                break;
            }
        }
        if (comparisonIndex < 0) { return [:measuring, 0]; }

        while (comparisonIndex > 0) {
            _timerTimes.remove(_timerTimes[0]);
            _projectedFinishTimes.remove(_projectedFinishTimes[0]);
            comparisonIndex -= 1;
        }

        var difference = _projectedFinishTimes[0] - projected;
        var minutes = ((difference.abs().toFloat() / 60000.0) + 0.5).toNumber();
        if (difference > ETA_TREND_TOLERANCE_MS) { return [:ahead, minutes]; }
        if (difference < -ETA_TREND_TOLERANCE_MS) { return [:behind, minutes]; }
        return [:on_pace, 0];
    }

    private function reset() as Void {
        _timerTimes = [];
        _projectedFinishTimes = [];
    }
}
