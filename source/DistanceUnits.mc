using Toybox.Lang;
using Toybox.System;

const METERS_PER_MILE = 1609.344;
const METERS_PER_KILOMETER = 1000.0;

class DistanceUnits {
    static function metersPerUnit() as Lang.Float {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE
            ? METERS_PER_MILE : METERS_PER_KILOMETER;
    }

    static function fromMeters(meters as Lang.Numeric) as Lang.Float { return meters.toFloat() / metersPerUnit(); }
    static function toMeters(value as Lang.Numeric) as Lang.Float { return value.toFloat() * metersPerUnit(); }
    static function label() as Lang.String {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE ? "MILES" : "KM";
    }
}
