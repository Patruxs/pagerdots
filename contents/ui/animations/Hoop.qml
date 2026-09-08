// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "hoop": the dot opens out into a hollow hoop, larger than itself, that rolls across
// to the new cell and closes back into a dot. `hoopT` is its progress from the old
// cell and `fill` how solid its inside is: 1 for a dot, 0 for a bare hoop.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.8

    property real hoopT: 0
    readonly property real hoopExtent: dot.size * 1.9

    function start(old, target) {
        // Cutting in mid-flight: the hoop rolls on from where it is.
        const mid = open.running || roll.running;
        setFrom(old, mid ? hoop.e : 1);
        hoopT = 0;
        if (roll.running) roll.restart();
        else if (!open.running) open.restart();
    }

    Rectangle {
        id: hoop
        objectName: "hoop"
        property real extent: anim.dot.size
        property real fill: 1
        readonly property real e: anim.dot.easeInOut(anim.hoopT)
        x: anim.fromX + (anim.dot.cx - anim.fromX) * hoop.e - hoop.extent / 2
        y: anim.fromY + (anim.dot.cy - anim.fromY) * hoop.e - hoop.extent / 2
        width: hoop.extent
        height: hoop.extent
        radius: hoop.extent / 2
        color: Qt.alpha(anim.dot.color, hoop.fill)
        border.color: anim.dot.color
        border.width: Math.max(1.2, anim.dot.size * 0.25)
        visible: false
        antialiasing: true
    }
    SequentialAnimation {
        id: open
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PropertyAction { target: hoop; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: hoop; property: "extent"; to: anim.hoopExtent; duration: anim.dot.unit * 0.35; easing.type: Easing.OutQuad }
            NumberAnimation { target: hoop; property: "fill"; to: 0; duration: anim.dot.unit * 0.35; easing.type: Easing.OutQuad }
        }
        ScriptAction { script: roll.restart() }
    }
    SequentialAnimation {
        id: roll
        ParallelAnimation {
            NumberAnimation { target: anim; property: "hoopT"; to: 1; duration: anim.dot.unit * 1.1 }
            // Opens back out if cut in on while closing.
            NumberAnimation { target: hoop; property: "extent"; to: anim.hoopExtent; duration: anim.dot.unit * 0.2 }
            NumberAnimation { target: hoop; property: "fill"; to: 0; duration: anim.dot.unit * 0.2 }
        }
        ParallelAnimation {
            NumberAnimation { target: hoop; property: "extent"; to: anim.dot.size; duration: anim.dot.unit * 0.35; easing.type: Easing.InOutQuad }
            NumberAnimation { target: hoop; property: "fill"; to: 1; duration: anim.dot.unit * 0.35; easing.type: Easing.InQuad }
        }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        PropertyAction { target: hoop; property: "visible"; value: false }
    }
}
