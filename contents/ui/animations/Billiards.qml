// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "billiards": the dot slides across at a steady pace and stops dead on the new cell,
// knocking a second dot out ahead of it, which flies on a cell and fades. `shift` is
// the dot's offset from the new cell.
DotAnimation {
    id: anim
    kind: "shift"
    travel: strikeTime
    along: shift

    property real shift: 0
    property real kickTo: 0
    property int strikeTime: dot.unit

    function start(old, target) {
        const c = dot.centreOf(target);
        const span = dot.vertical ? target.height : target.width;
        shift = dot.centreOf(old) + shift - c;
        // The struck dot flies on a whole cell the way the dot was going.
        kickTo = (shift < 0 ? 1 : -1) * span;
        strikeTime = dot.unit * Math.min(1.2, 0.4 + 0.4 * Math.abs(shift) / Math.max(1, span));
        billiards.restart();
    }

    Rectangle {
        id: struck
        objectName: "struck"
        property real kick: 0
        x: anim.dot.cx - anim.dot.size / 2 + (anim.dot.vertical ? 0 : struck.kick)
        y: anim.dot.cy - anim.dot.size / 2 + (anim.dot.vertical ? struck.kick : 0)
        width: anim.dot.size
        height: anim.dot.size
        radius: anim.dot.size / 2
        color: anim.dot.color
        visible: false
        antialiasing: true
    }
    SequentialAnimation {
        id: billiards
        PropertyAction { target: struck; property: "visible"; value: false }
        NumberAnimation { target: anim; property: "shift"; to: 0; duration: anim.strikeTime; easing.type: Easing.Linear }
        PropertyAction { target: struck; property: "kick"; value: 0 }
        PropertyAction { target: struck; property: "opacity"; value: 1 }
        PropertyAction { target: struck; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: struck; property: "kick"; to: anim.kickTo; duration: anim.dot.unit; easing.type: Easing.OutCubic }
            NumberAnimation { target: struck; property: "opacity"; to: 0; duration: anim.dot.unit; easing.type: Easing.InQuad }
        }
        PropertyAction { target: struck; property: "visible"; value: false }
    }
}
