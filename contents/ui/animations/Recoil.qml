// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "recoil": the dot pops up on the new cell at once, and the old one is kicked back
// along the row, away from it, fading as it goes.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 0.8

    property real kickTo: 0

    function start(old, target) {
        dot.placeGhost(old);
        const span = dot.vertical ? target.height : target.width;
        kickTo = (dot.centreOf(target) > dot.centreOf(old) ? -1 : 1) * span * 0.8;
        recoil.restart();
    }

    ParallelAnimation {
        id: recoil
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: anim.dot.ghost; property: "slide"; to: anim.kickTo; duration: anim.dot.unit * 0.9; easing.type: Easing.OutCubic }
                NumberAnimation { target: anim.dot.ghost; property: "opacity"; to: 0; duration: anim.dot.unit * 0.9; easing.type: Easing.InQuad }
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "scale"; from: 0; to: 1; duration: anim.dot.unit * 0.6; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }
}
