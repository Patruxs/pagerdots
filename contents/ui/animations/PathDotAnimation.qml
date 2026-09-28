// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

DotAnimation {
    id: route
    kind: "shift"
    travel: duration
    along: shift + dir * pos[0]
    across: pos[1] + carry * (1 - pathT) * (1 - pathT)

    property int duration: dot.unit * 2
    property real pathT: 0
    property real shift: 0
    property real carry: 0
    property int dir: 1
    property int cells: 1
    readonly property var pos: pathPoint(pathT)

    function pathPoint(t) {
        return [Math.abs(shift) * t, 0];
    }

    function start(old, target) {
        begin(old, target);
    }

    function begin(old, target) {
        carry = across;
        const c = dot.centreOf(target);
        shift = dot.centreOf(old) + along - c;
        dir = c > dot.centreOf(old) ? 1 : -1;
        const span = dot.vertical ? target.height : target.width;
        cells = Math.max(1, Math.round(Math.abs(shift) / Math.max(1, span)));
        pathT = 0;
        run.restart();
    }

    NumberAnimation {
        id: run
        target: route; property: "pathT"; from: 0; to: 1
        duration: route.duration
    }
}
