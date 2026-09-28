// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

DotAnimation {
    id: anim
    kind: "swap"

    readonly property real beamReach: dot.room * 2 + dot.size
    readonly property real beamThick: Math.max(1.5, dot.size * 0.3)

    function start(old, target) {
        setFrom(old);
        const mid = beam.running;
        beamOut.reach = mid ? beamIn.reach : dot.size;
        beamOut.thick = mid ? beamIn.thick : dot.size;
        beamOut.opacity = mid ? beamIn.opacity : 1;
        beam.restart();
    }

    component Bar: Rectangle {
        id: bar
        property real reach: anim.dot.size
        property real thick: anim.dot.size
        width: anim.dot.vertical ? bar.reach : bar.thick
        height: anim.dot.vertical ? bar.thick : bar.reach
        radius: Math.min(bar.width, bar.height) / 2
        color: anim.dot.color
        visible: false
        antialiasing: true
    }
    Bar {
        id: beamOut
        objectName: "beamOut"
        x: anim.fromX - width / 2
        y: anim.fromY - height / 2
    }
    Bar {
        id: beamIn
        objectName: "beamIn"
        x: anim.dot.cx - width / 2
        y: anim.dot.cy - height / 2
    }
    ParallelAnimation {
        id: beam
        SequentialAnimation {
            PropertyAction { target: beamOut; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: beamOut; property: "reach"; to: anim.beamReach; duration: anim.dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: beamOut; property: "thick"; to: anim.beamThick; duration: anim.dot.unit * 0.5; easing.type: Easing.OutQuad }
            }
            NumberAnimation { target: beamOut; property: "opacity"; to: 0; duration: anim.dot.unit * 0.7; easing.type: Easing.InQuad }
            PropertyAction { target: beamOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
            PropertyAction { target: beamIn; property: "reach"; value: anim.beamReach }
            PropertyAction { target: beamIn; property: "thick"; value: anim.beamThick }
            PropertyAction { target: beamIn; property: "opacity"; value: 0 }
            PropertyAction { target: beamIn; property: "visible"; value: true }
            PauseAnimation { duration: anim.dot.unit * 0.4 }
            NumberAnimation { target: beamIn; property: "opacity"; to: 1; duration: anim.dot.unit * 0.4; easing.type: Easing.OutQuad }
            PauseAnimation { duration: anim.dot.unit * 0.2 }
            ParallelAnimation {
                NumberAnimation { target: beamIn; property: "reach"; to: anim.dot.size; duration: anim.dot.unit * 0.6; easing.type: Easing.InOutQuad }
                NumberAnimation { target: beamIn; property: "thick"; to: anim.dot.size; duration: anim.dot.unit * 0.6; easing.type: Easing.InOutQuad }
            }
            PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
            PropertyAction { target: beamIn; property: "visible"; value: false }
        }
    }
}
