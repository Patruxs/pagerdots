// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "sparks": the dot bursts into a handful of sparks that fly across to the new cell,
// each on its own arc and a little behind the last, and gather into a new dot there.
// `swarmT` runs from 0 to 1 over the whole flight, and each spark takes its own
// staggered slice of it.
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
            // This spark's progress, 0 to 1, and the same eased in and out.
            readonly property real p: Math.max(0, Math.min(1, (anim.swarmT - index / count * 0.35) / 0.65))
            readonly property real e: anim.dot.easeInOut(p)
            // How far out the arc swings, alternating sides and varying from spark to spark.
            readonly property real reach: (index % 2 ? 1 : -1) * anim.dot.room * (0.4 + 0.6 * ((index * 5) % count) / count)
            readonly property real across: reach * Math.sin(Math.PI * e)
            readonly property real extent: anim.dot.size * (0.4 + 0.3 * ((index * 7) % count) / count)
            x: anim.fromX + (anim.dot.cx - anim.fromX) * e + (anim.dot.vertical ? across : 0) - extent / 2
            y: anim.fromY + (anim.dot.cy - anim.fromY) * e + (anim.dot.vertical ? 0 : across) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: anim.dot.color
            // Fades in as it leaves the old dot and out as it merges into the new one.
            opacity: Math.min(1, p * 5, (1 - p) * 5)
            visible: swarm.running
            antialiasing: true
        }
    }
    // The ghost shrinks away as the sparks leave it, and the dot grows on the new cell
    // as they arrive.
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
