// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "train": the dot breaks into a file of three beads that run across in line, each
// setting off a little after the last, and merge into a new dot on the new cell.
// `trainT` runs from 0 to 1 over the whole run and each bead takes its own slice of it.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.8

    property real trainT: 0
    readonly property real slice: 0.76

    function start(old, target) {
        // Cutting in mid-flight: the beads set off again from where the first one is,
        // and there is no dot left on the old cell to shrink away.
        const mid = train.running;
        setFrom(old, mid ? dot.easeInOut(Math.min(1, trainT / slice)) : 1);
        if (mid) dot.ghost.visible = false;
        else dot.placeGhost(old);
        train.restart();
    }

    Repeater {
        model: 3
        Rectangle {
            id: bead
            required property int index
            readonly property real p: Math.max(0, Math.min(1, (anim.trainT - bead.index * 0.12) / anim.slice))
            readonly property real e: anim.dot.easeInOut(bead.p)
            readonly property real extent: anim.dot.size * 0.5
            x: anim.fromX + (anim.dot.cx - anim.fromX) * bead.e - bead.extent / 2
            y: anim.fromY + (anim.dot.cy - anim.fromY) * bead.e - bead.extent / 2
            width: bead.extent
            height: bead.extent
            radius: bead.extent / 2
            color: anim.dot.color
            // Shows as it leaves the shrinking old dot and goes as it merges into the new one.
            opacity: Math.min(1, bead.p * 8, (1 - bead.p) * 8)
            visible: train.running
            antialiasing: true
        }
    }
    ParallelAnimation {
        id: train
        NumberAnimation { target: anim; property: "trainT"; from: 0; to: 1; duration: anim.dot.unit * 1.8 }
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.6; easing.type: Easing.InQuad }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PauseAnimation { duration: anim.dot.unit * 1.1 }
            NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.7; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }
}
