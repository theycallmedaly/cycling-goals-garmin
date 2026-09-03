using Toybox.Lang;

const RECENT_PACE_WINDOW_METERS = 8046.72;
const RECENT_PACE_SAMPLE_METERS = 160.9344;

class RecentPaceEstimator {
    private var _distances as Lang.Array<Lang.Numeric>;
    private var _timerTimes as Lang.Array<Lang.Numeric>;

    function initialize() {
        _distances = [];
        _timerTimes = [];
    }

    function update(distanceMeters as Lang.Numeric, timerMilliseconds as Lang.Numeric,
            rideAverageMps as Lang.Numeric or Null) as Lang.Float or Null {
        var distance = distanceMeters.toFloat();
        var timer = timerMilliseconds.toNumber();

        if (_distances.size() > 0) {
            var lastDistance = _distances[_distances.size() - 1];
            var lastTime = _timerTimes[_timerTimes.size() - 1];
            if (distance < lastDistance || timer < lastTime) { reset(); }
        }

        if (_distances.size() == 0
                || distance - _distances[_distances.size() - 1] >= RECENT_PACE_SAMPLE_METERS) {
            _distances.add(distance);
            _timerTimes.add(timer);
        }

        var cutoff = distance - RECENT_PACE_WINDOW_METERS;
        while (_distances.size() > 1 && _distances[1] <= cutoff) {
            _distances.remove(_distances[0]);
            _timerTimes.remove(_timerTimes[0]);
        }

        if (_distances.size() > 0) {
            var covered = distance - _distances[0];
            var duration = timer - _timerTimes[0];
            if (covered >= RECENT_PACE_WINDOW_METERS - 1.0 && duration > 0) {
                return covered / (duration.toFloat() / 1000.0);
            }
        }
        return rideAverageMps == null || rideAverageMps <= 0 ? null : rideAverageMps.toFloat();
    }

    static function formatEta(remainingMeters as Lang.Numeric, speedMps as Lang.Numeric or Null) as Lang.String {
        if (speedMps == null || speedMps <= 0) { return "--H:--M"; }
        var totalMinutes = (((remainingMeters.toFloat() / speedMps.toFloat()) / 60.0) + 0.5).toNumber();
        var hours = totalMinutes / 60;
        var minutes = totalMinutes % 60;
        return padTwo(hours) + "H:" + padTwo(minutes) + "M";
    }

    private function reset() as Void {
        _distances = [];
        _timerTimes = [];
    }

    private static function padTwo(value as Lang.Number) as Lang.String {
        return value < 10 ? "0" + value.toString() : value.toString();
    }
}
