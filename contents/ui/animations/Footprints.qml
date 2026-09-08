// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "footprints": a faint print is left on each cell as the dot passes over it and fades
// away behind it. The prints are laid out from the old cell towards the new one when
// the move starts, and each shows itself once the dot has gone by.
DotAnimation {
    id: anim

    property real printFrom: 0
    property real printStep: 0
    property int printCount: 0

    function start(old, target) {
        // One print on the old cell and one on every cell between it and the new one,
        // a cell's width apart, since all the cells are the same size.
        const along = dot.centreOf(target) - dot.centreOf(old);
        const span = dot.vertical ? target.height : target.width;
        printCount = 0;
        printStep = span * (along < 0 ? -1 : 1);
        printFrom = dot.centreOf(old);
        printCount = Math.min(prints.count, Math.max(1, Math.round(Math.abs(along) / Math.max(1, span))));
    }

    Repeater {
        id: prints
        model: 8
        Rectangle {
            id: mark
            required property int index
            readonly property real extent: anim.dot.size * 0.85
            readonly property real at: anim.printFrom + anim.printStep * index
            readonly property real head: anim.dot.vertical ? anim.dot.leadY : anim.dot.leadX
            // Gone by: the dot has moved on from this cell in the direction of travel.
            readonly property bool passed: index < anim.printCount
                                           && (anim.printStep > 0 ? head > at + anim.dot.size * 0.6
                                                                  : head < at - anim.dot.size * 0.6)
            x: (anim.dot.vertical ? anim.dot.cx : at) - extent / 2
            y: (anim.dot.vertical ? at : anim.dot.cy) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: anim.dot.color
            opacity: 0
            visible: opacity > 0
            antialiasing: true
            onPassedChanged: if (passed) fade.restart()
            SequentialAnimation {
                id: fade
                PropertyAction { target: mark; property: "opacity"; value: 0.5 }
                NumberAnimation { target: mark; property: "opacity"; to: 0; duration: anim.dot.unit * 3; easing.type: Easing.InQuad }
            }
        }
    }
}
