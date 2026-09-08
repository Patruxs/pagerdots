// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "boomerang": the dot first draws back a whole cell away from the new one, then
// flies across and lands. `shift` is the dot's offset from the new cell.
DotAnimation {
    id: anim
    kind: "shift"
    along: shift

    property real shift: 0
    property real backTo: 0

    function start(old, target) {
        const c = dot.centreOf(target);
        const span = dot.vertical ? target.height : target.width;
        shift = dot.centreOf(old) + shift - c;
        // A whole cell beyond the old one, away from the new one.
        backTo = dot.centreOf(old) - c + (c > dot.centreOf(old) ? -span : span);
        boomerang.restart();
    }

    SequentialAnimation {
        id: boomerang
        NumberAnimation { target: anim; property: "shift"; to: anim.backTo; duration: anim.dot.unit * 0.8; easing.type: Easing.InOutSine }
        NumberAnimation { target: anim; property: "shift"; to: 0; duration: anim.dot.unit * 1.2; easing.type: Easing.InOutCubic }
    }
}
