// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "pop": the ghost shrinks away on the old cell while the dot springs up on the new one.
DotAnimation {
    id: anim
    kind: "swap"

    function start(old, target) {
        dot.placeGhost(old);
        pop.restart();
    }

    ParallelAnimation {
        id: pop
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "scale"; from: 1; to: 0; duration: anim.dot.unit * 0.75; easing.type: Easing.InCubic }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "scale"; from: 0; to: 1; duration: anim.dot.unit * 1.5; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
    }
}
