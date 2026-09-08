// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "split": the dot divides into two half-size dots that swing out to either side of
// the row, travel across, and merge again on the new cell. `splitT` is the progress
// along the row and `spread` how far apart the halves are.
DotAnimation {
    id: anim
    kind: "swap"

    property real splitT: 0
    property real spread: 0

    function start(old, target) {
        // Cutting in mid-flight: the halves set off again from where they are, and
        // there is no dot left on the old cell to shrink away.
        const mid = split.running;
        setFrom(old, mid ? dot.easeInOut(splitT) : 1);
        if (mid) dot.ghost.visible = false;
        else dot.placeGhost(old);
        split.restart();
    }

    Repeater {
        model: 2
        Rectangle {
            id: half
            required property int index
            readonly property real e: anim.dot.easeInOut(anim.splitT)
            readonly property real across: (half.index ? 1 : -1) * anim.spread * anim.dot.room
            readonly property real extent: anim.dot.size * 0.7
            x: anim.fromX + (anim.dot.cx - anim.fromX) * half.e + (anim.dot.vertical ? half.across : 0) - half.extent / 2
            y: anim.fromY + (anim.dot.cy - anim.fromY) * half.e + (anim.dot.vertical ? 0 : half.across) - half.extent / 2
            width: half.extent
            height: half.extent
            radius: half.extent / 2
            color: anim.dot.color
            visible: split.running
            antialiasing: true
        }
    }
    ParallelAnimation {
        id: split
        NumberAnimation { target: anim; property: "splitT"; from: 0; to: 1; duration: anim.dot.unit * 1.6 }
        SequentialAnimation {
            NumberAnimation { target: anim; property: "spread"; to: 1; duration: anim.dot.unit * 0.7; easing.type: Easing.OutQuad }
            NumberAnimation { target: anim; property: "spread"; to: 0; duration: anim.dot.unit * 0.9; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.35; easing.type: Easing.InQuad }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PauseAnimation { duration: anim.dot.unit * 1.4 }
            NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.5; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }
    }
}
