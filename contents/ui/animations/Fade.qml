// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "fade": the ghost on the old cell and the dot on the new one cross-fade.
DotAnimation {
    id: anim
    kind: "swap"

    function start(old, target) {
        dot.placeGhost(old);
        fade.restart();
    }

    ParallelAnimation {
        id: fade
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "opacity"; from: 1; to: 0; duration: anim.dot.unit * 1.25; easing.type: Easing.OutCubic }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "opacity"; from: 0; to: 1; duration: anim.dot.unit * 1.25; easing.type: Easing.OutCubic }
    }
}
