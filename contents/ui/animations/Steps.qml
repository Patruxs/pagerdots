// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "steps": the dot jumps to the new cell in a few discrete stops, holding still
// between them. `stepT` runs from 0 to 1 over the move and is quantised into
// `stepCount` stops from `stepFrom`, the old cell's offset from the new one.
DotAnimation {
    id: anim
    kind: "shift"
    along: stepFrom * (1 - Math.ceil(stepT * stepCount) / stepCount)

    property real stepFrom: 0
    property real stepT: 0
    property int stepCount: 3

    function start(old, target) {
        const c = dot.centreOf(target);
        const span = dot.vertical ? target.height : target.width;
        stepFrom = dot.centreOf(old) + along - c;
        stepT = 0;
        // Three stops for a one-cell move, and one more for every cell beyond that.
        stepCount = Math.min(6, 2 + Math.max(1, Math.round(Math.abs(stepFrom) / Math.max(1, span))));
        steps.restart();
    }

    NumberAnimation {
        id: steps
        target: anim; property: "stepT"; from: 0; to: 1
        duration: anim.dot.unit * 0.6 * anim.stepCount
    }
}
