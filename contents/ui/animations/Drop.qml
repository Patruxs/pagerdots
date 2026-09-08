// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "drop": the ghost falls away off the old cell while a new dot drops onto the new
// one, landing with a small bounce.
DotAnimation {
    id: anim
    kind: "swap"

    function start(old, target) {
        dot.placeGhost(old);
        drop.restart();
    }

    ParallelAnimation {
        id: drop
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: anim.dot.ghost; property: "fall"; from: 0; to: anim.dot.room * 1.2; duration: anim.dot.unit; easing.type: Easing.InQuad }
                NumberAnimation { target: anim.dot.ghost; property: "opacity"; from: 1; to: 0; duration: anim.dot.unit; easing.type: Easing.InQuad }
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "opacity"; from: 0; to: 1; duration: anim.dot.unit * 0.5; easing.type: Easing.OutQuad }
        SequentialAnimation {
            NumberAnimation { target: anim; property: "across"; from: anim.dot.room * 1.2; to: 0; duration: anim.dot.unit * 0.9; easing.type: Easing.InQuad }
            NumberAnimation { target: anim; property: "across"; to: anim.dot.room * 0.3; duration: anim.dot.unit * 0.35; easing.type: Easing.OutQuad }
            NumberAnimation { target: anim; property: "across"; to: 0; duration: anim.dot.unit * 0.35; easing.type: Easing.InQuad }
        }
    }
}
