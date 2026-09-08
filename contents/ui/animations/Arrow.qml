// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "arrow": the dot sharpens into an arrowhead pointing at the new cell, shoots over,
// and rounds off into a dot again. `arrowT` is its progress from the old cell.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.3

    property real arrowT: 0

    function start(old, target) {
        // Cutting in mid-flight: the arrowhead turns and shoots on from where it is.
        const mid = sharpen.running || fly.running;
        setFrom(old, mid ? arrow.e : 1);
        if (!mid) dot.placeGhost(old);
        arrowT = 0;
        if (fly.running) fly.restart();
        else if (!sharpen.running) sharpen.restart();
    }

    Item {
        id: arrow
        objectName: "arrow"
        readonly property real arm: anim.dot.size * 1.2
        readonly property real thick: Math.max(1.5, anim.dot.size * 0.3)
        // Off like a shot, then coasting in.
        readonly property real e: 1 - Math.pow(1 - anim.arrowT, 3)
        // The tip, which the arms trail behind.
        x: anim.fromX + (anim.dot.cx - anim.fromX) * arrow.e
        y: anim.fromY + (anim.dot.cy - anim.fromY) * arrow.e
        rotation: anim.dot.vertical ? (anim.dot.cy < anim.fromY ? -90 : 90) : (anim.dot.cx < anim.fromX ? 180 : 0)
        scale: 0
        visible: false
        Repeater {
            model: 2
            Rectangle {
                id: arm
                required property int index
                x: -arrow.arm
                y: -arrow.thick / 2
                width: arrow.arm
                height: arrow.thick
                radius: arrow.thick / 2
                color: anim.dot.color
                transformOrigin: Item.Right
                rotation: arm.index ? 45 : -45
                antialiasing: true
            }
        }
    }
    SequentialAnimation {
        id: sharpen
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PropertyAction { target: arrow; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: arrow; property: "scale"; to: 1; duration: anim.dot.unit * 0.3; easing.type: Easing.OutQuad }
            NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.3; easing.type: Easing.InQuad }
        }
        PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        ScriptAction { script: fly.restart() }
    }
    SequentialAnimation {
        id: fly
        NumberAnimation { target: anim; property: "arrowT"; to: 1; duration: anim.dot.unit * 0.7 }
        PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        ParallelAnimation {
            NumberAnimation { target: arrow; property: "scale"; to: 0; duration: anim.dot.unit * 0.3; easing.type: Easing.InQuad }
            NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.4; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }
        PropertyAction { target: arrow; property: "visible"; value: false }
    }
}
