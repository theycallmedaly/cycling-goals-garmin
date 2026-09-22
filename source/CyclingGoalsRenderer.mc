using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class CyclingGoalsRenderer {
    function draw(dc as Graphics.Dc, state as CyclingGoalsScreenState) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        if (!state.configured) {
            dc.drawText(x, y - 18, Graphics.FONT_SMALL,
                Application.loadResource(Rez.Strings.NoGoals), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(x, y + 10, Graphics.FONT_XTINY,
                Application.loadResource(Rez.Strings.OpenSettings), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        if (state.distanceGoal.displayMode == :bonus_prompt) {
            drawBonusPrompt(dc, state.distanceGoal, false);
            return;
        }
        if (state.elevationGoal.displayMode == :bonus_prompt) {
            drawBonusPrompt(dc, state.elevationGoal, true);
            return;
        }

        var distanceStatus = progressColor(state.distanceGoal.displayTargetMeters,
            state.distanceGoal.remainingMeters);
        var elevationStatus = progressColor(state.elevationGoal.displayTargetMeters,
            state.elevationGoal.remainingMeters);
        var etaBackground = state.showRideStreak
            ? Graphics.COLOR_BLACK : etaColor(state.etaTrendState);
        var distanceBottom = (dc.getHeight() * 37) / 100;
        var etaBottom = (dc.getHeight() * 63) / 100;
        var distanceBonus = state.distanceGoal.displayMode == :bonus;
        var elevationBonus = state.elevationGoal.displayMode == :bonus;
        var distanceBackground = distanceBonus ? Graphics.COLOR_GREEN : Graphics.COLOR_BLACK;
        dc.setColor(distanceBackground, distanceBackground);
        dc.fillRectangle(0, 0, dc.getWidth(), distanceBottom);
        dc.setColor(etaBackground, etaBackground);
        dc.fillRectangle(0, distanceBottom, dc.getWidth(), etaBottom - distanceBottom);
        var elevationBackground = elevationBonus ? Graphics.COLOR_GREEN : Graphics.COLOR_BLACK;
        dc.setColor(elevationBackground, elevationBackground);
        dc.fillRectangle(0, etaBottom, dc.getWidth(), dc.getHeight() - etaBottom);

        if (!distanceBonus) { drawStatusRails(dc, 0, distanceBottom, distanceStatus); }
        if (!elevationBonus) {
            drawStatusRails(dc, etaBottom, dc.getHeight(), elevationStatus);
        }

        dc.setColor(Graphics.COLOR_WHITE, distanceBackground);
        dc.drawText(x, 4, Graphics.FONT_XTINY,
            distanceBonus ? "BONUS MILES REMAINING"
                : Application.loadResource(Rez.Strings.RemainingToday),
            Graphics.TEXT_JUSTIFY_CENTER);
        var distanceCenter = (24 + distanceBottom) / 2;
        var etaCenter = distanceBottom + ((etaBottom - distanceBottom) / 2);
        var elevationCenter = etaBottom + ((dc.getHeight() - etaBottom) / 2);

        dc.drawText(x, distanceCenter - 12, Graphics.FONT_NUMBER_THAI_HOT,
            DistanceUnits.fromMeters(state.distanceGoal.remainingMeters).format("%.2f")
                + (state.distanceWeekdayLimitApplied && !distanceBonus ? "*" : ""),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, distanceCenter + 14, Graphics.FONT_SMALL,
            DistanceUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
        drawGoalProgressBar(dc, distanceBottom, state.distanceGoal.displayTargetMeters,
            state.distanceGoal.remainingMeters, distanceBonus);

        var etaForeground = etaBackground == Graphics.COLOR_GREEN
            ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        dc.setColor(etaForeground, etaBackground);
        dc.drawLine(24, distanceBottom, dc.getWidth() - 24, distanceBottom);
        if (state.showRideStreak) {
            var streakLabelFont = Graphics.FONT_TINY;
            var streakNumberFont = Graphics.FONT_NUMBER_THAI_HOT;
            var streakTop = distanceBottom + 2;
            var streakBottom = etaBottom - 3;
            var labelHeight = dc.getFontHeight(streakLabelFont);
            var numberHeight = dc.getFontHeight(streakNumberFont);
            var freeHeight = streakBottom - streakTop - labelHeight - numberHeight;
            var verticalGap = freeHeight > 0 ? freeHeight / 3 : 0;
            var labelCenter = streakTop + verticalGap + (labelHeight / 2);
            var numberCenter = labelCenter + (labelHeight / 2)
                + verticalGap + (numberHeight / 2);
            dc.drawText(x, labelCenter, streakLabelFont,
                "RIDE STREAK",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(x, numberCenter, streakNumberFont,
                state.rideStreakCount.toString(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var etaValueX = (dc.getWidth() * 33) / 100;
            var etaTrendX = (dc.getWidth() * 83) / 100;
            dc.drawText(etaValueX, distanceBottom + 8, Graphics.FONT_XTINY,
                "DIST. ETA", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(etaValueX, etaCenter + 3, Graphics.FONT_NUMBER_MEDIUM,
                state.etaText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            drawEtaTrend(dc, etaTrendX, etaCenter,
                state.etaTrendState, state.etaTrendMinutes);
        }
        dc.drawLine(24, etaBottom, dc.getWidth() - 24, etaBottom);

        dc.setColor(elevationBonus ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE,
            elevationBackground);
        if (elevationBonus) {
            dc.drawText(x, etaBottom + 3, Graphics.FONT_XTINY,
                "BONUS ELEVATION REMAINING", Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(x, elevationCenter - 12, Graphics.FONT_NUMBER_THAI_HOT,
            ElevationUnits.fromMeters(state.elevationGoal.remainingMeters).format("%.0f")
                + (state.elevationWeekdayLimitApplied && !elevationBonus ? "*" : ""),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, elevationCenter + 14, Graphics.FONT_SMALL,
            ElevationUnits.label(), Graphics.TEXT_JUSTIFY_CENTER);
        drawGoalProgressBar(dc, dc.getHeight(), state.elevationGoal.displayTargetMeters,
            state.elevationGoal.remainingMeters, elevationBonus);
    }

    private function drawGoalProgressBar(dc as Graphics.Dc, bottom as Lang.Number,
            target as Lang.Numeric, remaining as Lang.Numeric,
            isBonus as Lang.Boolean) as Void {
        var segments = 7;
        var sideMargin = 24;
        var gap = 5;
        var barHeight = 6;
        var availableWidth = dc.getWidth() - (sideMargin * 2);
        var segmentWidth = (availableWidth - (gap * (segments - 1))) / segments;
        var completedFraction = target <= 0
            ? 1.0 : (target.toFloat() - remaining.toFloat()) / target.toFloat();
        var completedFourteenths = completedFraction * 14.0;
        if (completedFourteenths < 0) { completedFourteenths = 0.0; }
        if (completedFourteenths > 14) { completedFourteenths = 14.0; }
        var y = bottom - 12;
        for (var segment = 0; segment < segments; segment += 1) {
            var left = sideMargin + segment * (segmentWidth + gap);
            if (segment == 3) {
                var halfWidth = ((segmentWidth - gap) / 2).toNumber();
                var secondHalfWidth = segmentWidth - gap - halfWidth;
                drawProgressDashBlock(dc, left, y, halfWidth, barHeight,
                    completedFourteenths, 6.0, 7.0, isBonus);
                drawProgressDashBlock(dc, left + halfWidth + gap, y,
                    secondHalfWidth, barHeight, completedFourteenths,
                    7.0, 8.0, isBonus);
            } else {
                var start = segment * 2.0;
                var end = (segment + 1) * 2.0;
                drawProgressDashBlock(dc, left, y, segmentWidth, barHeight,
                    completedFourteenths, start, end, isBonus);
            }
        }
    }

    private function drawProgressDashBlock(dc as Graphics.Dc, left as Lang.Number,
            top as Lang.Number, width as Lang.Number, baseHeight as Lang.Number,
            progress as Lang.Numeric, start as Lang.Numeric, end as Lang.Numeric,
            isBonus as Lang.Boolean) as Void {
        var height = progressDashHeight(progress, start, end, baseHeight);
        // Keep every dash on the same baseline; the current dash grows upward.
        var adjustedTop = top - (height - baseHeight);
        drawProgressDash(dc, left, adjustedTop, width, height,
            progressDashColor(progress, start, end, isBonus), isBonus);
    }

    function progressDashHeight(progress as Lang.Numeric, start as Lang.Numeric,
            end as Lang.Numeric, baseHeight as Lang.Number) as Lang.Number {
        return progress >= start && progress < end ? baseHeight * 2 : baseHeight;
    }

    private function drawProgressDash(dc as Graphics.Dc, left as Lang.Number,
            top as Lang.Number, width as Lang.Number, height as Lang.Number,
            color as Graphics.ColorType, isBonus as Lang.Boolean) as Void {
        if (isBonus) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.fillRectangle(left - 1, top - 1, width + 2, height + 2);
        }
        dc.setColor(color, color);
        dc.fillRectangle(left, top, width, height);
    }

    private function progressDashColor(progress as Lang.Numeric, start as Lang.Numeric,
            end as Lang.Numeric, isBonus as Lang.Boolean) as Graphics.ColorType {
        if (progress >= end) { return Graphics.COLOR_GREEN; }
        if (isBonus) { return Graphics.COLOR_BLUE; }
        var halfway = start.toFloat() + ((end.toFloat() - start.toFloat()) / 2.0);
        return progress >= halfway ? Graphics.COLOR_YELLOW : Graphics.COLOR_RED;
    }

    private function progressColor(target as Lang.Numeric,
            remaining as Lang.Numeric) as Graphics.ColorType {
        if (target <= 0 || remaining <= 0) { return Graphics.COLOR_GREEN; }
        var completedFraction = (target.toFloat() - remaining.toFloat()) / target.toFloat();
        return completedFraction < 0.75 ? Graphics.COLOR_RED : Graphics.COLOR_WHITE;
    }

    private function etaColor(state as Lang.Symbol) as Graphics.ColorType {
        if (state == :ahead) { return Graphics.COLOR_GREEN; }
        if (state == :behind) { return Graphics.COLOR_RED; }
        return Graphics.COLOR_BLACK;
    }

    private function drawStatusRails(dc as Graphics.Dc, top as Lang.Number,
            bottom as Lang.Number, color as Graphics.ColorType) as Void {
        var railWidth = 6;
        dc.setColor(color, color);
        dc.fillRectangle(0, top, railWidth, bottom - top);
        dc.fillRectangle(dc.getWidth() - railWidth, top, railWidth, bottom - top);
    }

    private function drawBonusPrompt(dc as Graphics.Dc, goal as RideGoalState,
            isElevation as Lang.Boolean) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = width / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var targetText = isElevation
            ? ElevationUnits.fromMeters(goal.bonusTargetMeters).format("%.0f")
                + " " + ElevationUnits.label()
            : DistanceUnits.fromMeters(goal.bonusTargetMeters).format("%.0f")
                + " " + DistanceUnits.label();
        dc.drawText(center, 22, Graphics.FONT_SMALL,
            goal.bonusRoundsAccepted == 0 ? "TODAY'S GOAL COMPLETE" : "BONUS GOAL COMPLETE",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(center, 66, Graphics.FONT_MEDIUM,
            "CHASE " + targetText + (goal.bonusRoundsAccepted == 0 ? " BONUS?" : " MORE?"),
            Graphics.TEXT_JUSTIFY_CENTER);

        var buttonTop = (height * 58) / 100;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        dc.fillRectangle(8, buttonTop, (width / 2) - 12, height - buttonTop - 10);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        dc.fillRectangle((width / 2) + 4, buttonTop, (width / 2) - 12,
            height - buttonTop - 10);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_GREEN);
        dc.drawText(width / 4, buttonTop + ((height - buttonTop) / 2) - 10,
            Graphics.FONT_LARGE, "YES", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_DK_GRAY);
        dc.drawText((width * 3) / 4, buttonTop + ((height - buttonTop) / 2) - 10,
            Graphics.FONT_LARGE, "NO", Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawEtaTrend(dc as Graphics.Dc, x as Lang.Number,
            centerY as Lang.Number, state as Lang.Symbol, minutes as Lang.Number) as Void {
        var iconX = x - 33;
        var textX = x + 7;
        if (state == :ahead) {
            drawTrendArrow(dc, iconX, centerY - 3, true);
            dc.drawText(textX, centerY - 13, Graphics.FONT_MEDIUM,
                minutes.format("%02d") + " MIN", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL,
                "AHEAD", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (state == :behind) {
            drawTrendArrow(dc, iconX, centerY - 3, false);
            dc.drawText(textX, centerY - 13, Graphics.FONT_MEDIUM,
                minutes.format("%02d") + " MIN", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL,
                "BEHIND", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (state == :on_pace) {
            drawPaceMarker(dc, iconX, centerY);
            dc.drawText(textX, centerY - 12, Graphics.FONT_MEDIUM,
                "ON", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(textX, centerY + 10, Graphics.FONT_SMALL,
                "PACE", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x, centerY - 1, Graphics.FONT_SMALL,
                "MEASURING", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawPaceMarker(dc as Graphics.Dc, x as Lang.Number,
            y as Lang.Number) as Void {
        dc.fillPolygon([
            [x, y - 9], [x + 3, y - 3], [x + 9, y], [x + 3, y + 3],
            [x, y + 9], [x - 3, y + 3], [x - 9, y], [x - 3, y - 3]
        ]);
    }

    private function drawTrendArrow(dc as Graphics.Dc, x as Lang.Number,
            y as Lang.Number, pointsUp as Lang.Boolean) as Void {
        var points = pointsUp
            ? [[x, y - 6], [x - 8, y + 6], [x + 8, y + 6]]
            : [[x - 8, y - 6], [x + 8, y - 6], [x, y + 6]];
        dc.fillPolygon(points);
    }
}
