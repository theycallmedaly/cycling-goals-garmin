using Toybox.System;

class DistanceUnits {
    const METERS_PER_MILE = 1609.344;
    const METERS_PER_KILOMETER = 1000.0;

    static function metersPerUnit() as Float {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE
            ? METERS_PER_MILE : METERS_PER_KILOMETER;
    }

    static function fromMeters(meters as Numeric) as Float { return meters.toFloat() / metersPerUnit(); }
    static function toMeters(value as Numeric) as Float { return value.toFloat() * metersPerUnit(); }
    static function label() as String {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE ? "MILES" : "KM";
    }
}

