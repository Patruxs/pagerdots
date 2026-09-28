// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.8

    property real wheelT: 0
    property real spin: 0
    property real spinTo: 0

    function start(old, target) {
        const mid = flatten.running || roll.running;
        setFrom(old, mid ? wheel.e : 1);
        wheelT = 0;
        const c = dot.centreOf(target);
        const from = dot.vertical ? fromY : fromX;
        const span = dot.vertical ? target.height : target.width;
        const turns = Math.max(1, Math.round(Math.abs(c - from) / Math.max(1, span)));
        spinTo = Math.round((spin + Math.sign(c - from) * 360 * turns) / 180) * 180;
        if (roll.running) roll.restart();
        else if (!flatten.running) flatten.restart();
    }

    Rectangle {
        id: wheel
        objectName: "wheel"
        property real len: anim.dot.size
        property real thick: anim.dot.size
        readonly property real e: anim.dot.easeInOutQuad(anim.wheelT)
        x: anim.fromX + (anim.dot.cx - anim.fromX) * wheel.e - wheel.len / 2
        y: anim.fromY + (anim.dot.cy - anim.fromY) * wheel.e - wheel.thick / 2
        width: wheel.len
        height: wheel.thick
        radius: wheel.thick / 2
        color: anim.dot.color
        rotation: anim.spin + (anim.dot.vertical ? 90 : 0)
        visible: false
        antialiasing: true
    }
    SequentialAnimation {
        id: flatten
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PropertyAction { target: wheel; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: wheel; property: "len"; to: anim.dot.size * 2.4; duration: anim.dot.unit * 0.3; easing.type: Easing.OutQuad }
            NumberAnimation { target: wheel; property: "thick"; to: Math.max(1.5, anim.dot.size * 0.4); duration: anim.dot.unit * 0.3; easing.type: Easing.OutQuad }
        }
        ScriptAction { script: roll.restart() }
    }
    SequentialAnimation {
        id: roll
        ParallelAnimation {
            NumberAnimation { target: anim; property: "wheelT"; to: 1; duration: anim.dot.unit * 1.2 }
            NumberAnimation { target: anim; property: "spin"; to: anim.spinTo; duration: anim.dot.unit * 1.2; easing.type: Easing.InOutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: wheel; property: "len"; to: anim.dot.size; duration: anim.dot.unit * 0.3; easing.type: Easing.InOutQuad }
            NumberAnimation { target: wheel; property: "thick"; to: anim.dot.size; duration: anim.dot.unit * 0.3; easing.type: Easing.InOutQuad }
        }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        PropertyAction { target: wheel; property: "visible"; value: false }
        PropertyAction { target: anim; property: "spin"; value: 0 }
    }
}
