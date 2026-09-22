using Toybox.Lang;

class EtaTrendState {
    var trend as Lang.Symbol;
    var minutes as Lang.Number;

    function initialize(trend as Lang.Symbol, minutes as Lang.Number) {
        self.trend = trend;
        self.minutes = minutes;
    }
}
