// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "burst": the dot on the old cell bursts into pieces that fly out all round it and
// fade, while pieces fly in from all round the new cell and gather into the dot.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.3

    readonly property real burstReach: dot.room + dot.size * 0.2

    function start(old, target) {
        setFrom(old);
        // Cutting in while the pieces are still gathering on the old cell: they fly
        // back out from where they are, and whatever dot had formed shrinks away.
        const mid = burst.running;
        burstOut.dist = mid ? burstIn.dist : 0;
        burstOut.opacity = mid ? burstIn.opacity : 1;
        dot.placeGhost(old, mid ? dot.pill.scale : 1);
        burst.restart();
    }

    component Pieces: Item {
        id: pieces
        property real dist: 0       // how far out from the centre the pieces are
        readonly property real extent: anim.dot.size * 0.42
        visible: false
        Repeater {
            model: 6
            Rectangle {
                id: piece
                required property int index
                readonly property real angle: (piece.index + 0.5) * Math.PI / 3
                x: Math.cos(piece.angle) * pieces.dist - pieces.extent / 2
                y: Math.sin(piece.angle) * pieces.dist - pieces.extent / 2
                width: pieces.extent
                height: pieces.extent
                radius: pieces.extent / 2
                color: anim.dot.color
                antialiasing: true
            }
        }
    }
    Pieces {
        id: burstOut
        objectName: "burstOut"
        x: anim.fromX
        y: anim.fromY
    }
    Pieces {
        id: burstIn
        objectName: "burstIn"
        x: anim.dot.cx
        y: anim.dot.cy
    }
    ParallelAnimation {
        id: burst
        // The outgoing pieces start from whatever start() set them to.
        SequentialAnimation {
            PropertyAction { target: burstOut; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.3; easing.type: Easing.InQuad }
                NumberAnimation { target: burstOut; property: "dist"; to: anim.burstReach; duration: anim.dot.unit * 0.7; easing.type: Easing.OutCubic }
                NumberAnimation { target: burstOut; property: "opacity"; to: 0; duration: anim.dot.unit * 0.7; easing.type: Easing.InQuad }
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
            PropertyAction { target: burstOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PropertyAction { target: burstIn; property: "dist"; value: anim.burstReach }
            PropertyAction { target: burstIn; property: "opacity"; value: 0 }
            PropertyAction { target: burstIn; property: "visible"; value: true }
            PauseAnimation { duration: anim.dot.unit * 0.3 }
            ParallelAnimation {
                NumberAnimation { target: burstIn; property: "opacity"; to: 1; duration: anim.dot.unit * 0.3; easing.type: Easing.OutQuad }
                NumberAnimation { target: burstIn; property: "dist"; to: 0; duration: anim.dot.unit * 0.6; easing.type: Easing.InCubic }
                SequentialAnimation {
                    PauseAnimation { duration: anim.dot.unit * 0.45 }
                    NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.55; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
                }
            }
            PropertyAction { target: burstIn; property: "visible"; value: false }
        }
    }
}
