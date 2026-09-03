using Toybox.Lang;
using Toybox.System;

const ELEVATION_FEET_PER_METER = 3.280839895;

class ElevationUnits {
    static function fromMeters(meters as Lang.Numeric) as Lang.Float {
        return System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE
            ? meters.toFloat() * ELEVATION_FEET_PER_METER : meters.toFloat();
    }

    static function toMeters(value as Lang.Numeric) as Lang.Float {
        return System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE
            ? value.toFloat() / ELEVATION_FEET_PER_METER : value.toFloat();
    }

    static function label() as Lang.String {
        return System.getDeviceSettings().elevationUnits == System.UNIT_STATUTE ? "FT" : "M";
    }
}
