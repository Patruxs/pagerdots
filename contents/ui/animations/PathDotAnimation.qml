// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// Base of the animations that move the dot between the cells on a path of their own
// ("loop", "volley" and "flip"). `pathT` runs from 0 to 1 over the move; `shift` holds
// the old cell's offset from the new one when the move starts, and pathPoint() gives
// how far the dot has come along the row from there and how far it is across it. A
// move that cuts in on another carries the offset across the row over (`carry`) and
// eases it away, so the dot never jumps back onto the row.
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
    property int dir: 1         // which way along the row the move goes
    property int cells: 1       // how many cells it crosses
    readonly property var pos: pathPoint(pathT)

    // [distance come along the row, offset across it] at progress t. `dist` is the
    // whole distance to cover and `reach` how far across the row there is room to go.
    function pathPoint(t) {
        return [Math.abs(shift) * t, 0];
    }

    function start(old, target) {
        begin(old, target);
    }
    // The shared part of start(), for animations that add to it.
    function begin(old, target) {
        // Cutting in mid-flight: the path sets off again from where the dot is, and
        // whatever offset across the row it has is eased away over the new move.
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
