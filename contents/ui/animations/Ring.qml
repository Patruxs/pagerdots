// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "ring": the dot on the old cell opens out into a ring that spreads and fades, while
// a ring closes in on the new cell and fills to become the dot.
DotAnimation {
    id: anim
    kind: "swap"

    function start(old, target) {
        setFrom(old);
        // Cutting in while a ring is still closing on the old cell: open back out from
        // wherever it got to, rather than from a dot that was never there.
        const closing = ring.running;
        irisOut.extent = closing ? irisIn.extent : dot.size;
        irisOut.fill = closing ? irisIn.fill : 1;
        irisOut.opacity = closing ? irisIn.opacity : 1;
        ring.restart();
    }

    // `fill` is how solid the disc inside the ring is: 1 for a dot, 0 for a bare ring.
    component Iris: Rectangle {
        property real extent: anim.dot.size
        property real fill: 1
        width: extent
        height: extent
        radius: extent / 2
        color: Qt.alpha(anim.dot.color, fill)
        border.color: anim.dot.color
        border.width: Math.max(1, anim.dot.size / 4)
        visible: false
        antialiasing: true
    }
    Iris {
        id: irisOut
        objectName: "irisOut"
        x: anim.fromX - extent / 2
        y: anim.fromY - extent / 2
    }
    Iris {
        id: irisIn
        objectName: "irisIn"
        x: anim.dot.cx - extent / 2
        y: anim.dot.cy - extent / 2
    }
    ParallelAnimation {
        id: ring
        // The opening ring starts from whatever start() set it to.
        SequentialAnimation {
            PropertyAction { target: irisOut; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: irisOut; property: "fill"; to: 0; duration: anim.dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: irisOut; property: "extent"; to: anim.dot.size * 2.6; duration: anim.dot.unit * 1.5; easing.type: Easing.OutCubic }
                NumberAnimation { target: irisOut; property: "opacity"; to: 0; duration: anim.dot.unit * 1.5; easing.type: Easing.InQuad }
            }
            PropertyAction { target: irisOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
            PropertyAction { target: irisIn; property: "extent"; value: anim.dot.size * 2.6 }
            PropertyAction { target: irisIn; property: "fill"; value: 0 }
            PropertyAction { target: irisIn; property: "opacity"; value: 0 }
            PropertyAction { target: irisIn; property: "visible"; value: true }
            PauseAnimation { duration: anim.dot.unit * 0.25 }
            ParallelAnimation {
                NumberAnimation { target: irisIn; property: "opacity"; to: 1; duration: anim.dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: irisIn; property: "extent"; to: anim.dot.size; duration: anim.dot.unit * 1.5; easing.type: Easing.InOutCubic }
                SequentialAnimation {
                    PauseAnimation { duration: anim.dot.unit * 0.9 }
                    NumberAnimation { target: irisIn; property: "fill"; to: 1; duration: anim.dot.unit * 0.6; easing.type: Easing.InQuad }
                }
            }
            PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
            PropertyAction { target: irisIn; property: "visible"; value: false }
        }
    }
}
