// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.25

    function start(old, target) {
        const forward = dot.centreOf(target) > dot.centreOf(old);
        keep = forward ? 1 : -1;
        dot.placeGhost(old);
        dot.ghost.keep = forward ? -1 : 1;
        fade.restart();
    }

    readonly property bool pill: dot.elongation > 0

    ParallelAnimation {
        id: fade
        SequentialAnimation {
            PropertyAction { target: anim.dot.ghost; property: "opacity"; value: 1 }
            PauseAnimation { duration: anim.pill ? anim.dot.unit * 0.5 : 0 }
            NumberAnimation {
                target: anim.dot.ghost; property: "opacity"; from: 1; to: 0
                duration: anim.dot.unit * (anim.pill ? 0.75 : 1.25)
                easing.type: anim.pill ? Easing.InOutQuad : Easing.OutCubic
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "opacity"; from: 0; to: 1; duration: anim.dot.unit * 1.25; easing.type: Easing.OutCubic }
        NumberAnimation { target: anim.dot.ghost; property: "extent"; from: 1; to: 0; duration: anim.dot.unit; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "extent"; from: 0; to: 1; duration: anim.dot.unit; easing.type: Easing.OutQuad }
    }
}
