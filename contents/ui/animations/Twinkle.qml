// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "twinkle": the dot on the old cell collapses into a four-point star, two thin bars
// crossed, that spins as it flares and shrinks away, while a star flares up on the
// new cell, spins, and rounds off into the dot.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.2

    readonly property real starReach: dot.room + dot.size / 4

    function start(old, target) {
        setFrom(old);
        // Cutting in while a star is still flaring on the old cell: it carries on from
        // there as the outgoing star, and whatever dot had formed under it shrinks away.
        const mid = twinkle.running;
        starOut.reach = mid ? starIn.reach : 0;
        starOut.turn = mid ? starIn.turn : 0;
        dot.placeGhost(old, mid ? dot.pill.scale : 1);
        twinkle.restart();
    }

    component Star: Item {
        id: star
        property real reach: 0      // length of each arm from the centre
        property real turn: 0       // in degrees
        property real turnTo: 0
        readonly property real thick: Math.max(1.2, anim.dot.size * 0.22)
        rotation: star.turn
        visible: false
        Repeater {
            model: 2
            Rectangle {
                id: arm
                required property int index
                x: -star.reach
                y: -star.thick / 2
                width: star.reach * 2
                height: star.thick
                radius: star.thick / 2
                color: anim.dot.color
                rotation: arm.index * 90
                antialiasing: true
            }
        }
    }
    Star {
        id: starOut
        objectName: "starOut"
        x: anim.fromX
        y: anim.fromY
    }
    Star {
        id: starIn
        objectName: "starIn"
        x: anim.dot.cx
        y: anim.dot.cy
    }
    ParallelAnimation {
        id: twinkle
        // The outgoing star starts from whatever start() set it to.
        SequentialAnimation {
            PropertyAction { target: starOut; property: "visible"; value: true }
            ScriptAction { script: starOut.turnTo = starOut.turn + 90 }
            ParallelAnimation {
                NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.35; easing.type: Easing.InQuad }
                NumberAnimation { target: starOut; property: "reach"; to: anim.starReach; duration: anim.dot.unit * 0.35; easing.type: Easing.OutQuad }
                NumberAnimation { target: starOut; property: "turn"; to: starOut.turnTo; duration: anim.dot.unit * 0.85 }
                SequentialAnimation {
                    PauseAnimation { duration: anim.dot.unit * 0.35 }
                    NumberAnimation { target: starOut; property: "reach"; to: 0; duration: anim.dot.unit * 0.5; easing.type: Easing.InQuad }
                }
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
            PropertyAction { target: starOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PropertyAction { target: starIn; property: "reach"; value: 0 }
            PropertyAction { target: starIn; property: "turn"; value: 0 }
            PropertyAction { target: starIn; property: "visible"; value: true }
            PauseAnimation { duration: anim.dot.unit * 0.35 }
            ParallelAnimation {
                NumberAnimation { target: starIn; property: "turn"; to: 90; duration: anim.dot.unit * 0.85 }
                SequentialAnimation {
                    NumberAnimation { target: starIn; property: "reach"; to: anim.starReach; duration: anim.dot.unit * 0.35; easing.type: Easing.OutQuad }
                    ParallelAnimation {
                        NumberAnimation { target: starIn; property: "reach"; to: 0; duration: anim.dot.unit * 0.5; easing.type: Easing.InQuad }
                        NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.5; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                    }
                }
            }
            PropertyAction { target: starIn; property: "visible"; value: false }
        }
    }
}
