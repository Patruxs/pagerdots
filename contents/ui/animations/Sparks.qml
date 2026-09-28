// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 2.4

    property real swarmT: 0

    function start(old, target) {
        dot.placeGhost(old);
        setFrom(old);
        swarm.restart();
    }

    Repeater {
        model: 6
        Rectangle {
            id: spark
            required property int index
            readonly property int count: 6
            readonly property real p: Math.max(0, Math.min(1, (anim.swarmT - index / count * 0.35) / 0.65))
            readonly property real e: anim.dot.easeInOut(p)
            readonly property real reach: (index % 2 ? 1 : -1) * anim.dot.room * (0.4 + 0.6 * ((index * 5) % count) / count)
            readonly property real across: reach * Math.sin(Math.PI * e)
            readonly property real extent: anim.dot.size * (0.4 + 0.3 * ((index * 7) % count) / count)
            x: anim.fromX + (anim.dot.cx - anim.fromX) * e + (anim.dot.vertical ? across : 0) - extent / 2
            y: anim.fromY + (anim.dot.cy - anim.fromY) * e + (anim.dot.vertical ? 0 : across) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: anim.dot.color
            opacity: Math.min(1, p * 5, (1 - p) * 5)
            visible: swarm.running
            antialiasing: true
        }
    }

    ParallelAnimation {
        id: swarm
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "scale"; from: 1; to: 0; duration: anim.dot.unit * 0.6; easing.type: Easing.InCubic }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim; property: "swarmT"; from: 0; to: 1; duration: anim.dot.unit * 2.4 }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PauseAnimation { duration: anim.dot.unit * 1.5 }
            NumberAnimation { target: anim.dot.pill; property: "scale"; from: 0; to: 1; duration: anim.dot.unit * 1.2; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
        }
    }
}
