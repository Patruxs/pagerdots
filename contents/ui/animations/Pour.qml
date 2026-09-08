// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "pour": the dot drains from the old cell into the new one. The ghost shrinks on the
// old cell as the dot grows on the new one, joined by a thin stream that is thickest
// while the two are the same size, and a bead runs down the stream to show the flow.
DotAnimation {
    id: anim
    kind: "swap"

    property real pourT: 0

    function start(old, target) {
        dot.placeGhost(old);
        setFrom(old);
        pour.restart();
    }

    Rectangle {
        id: stream
        objectName: "stream"
        readonly property real flow: Math.sqrt(Math.max(0, 4 * anim.dot.ghost.scale * anim.dot.pill.scale))
        readonly property real thickness: Math.max(1, anim.dot.size * 0.3) * Math.min(1, flow)
        readonly property real span: anim.dot.vertical ? Math.abs(anim.dot.cy - anim.fromY) : Math.abs(anim.dot.cx - anim.fromX)
        x: anim.dot.vertical ? anim.dot.cx - thickness / 2 : Math.min(anim.dot.cx, anim.fromX)
        y: anim.dot.vertical ? Math.min(anim.dot.cy, anim.fromY) : anim.dot.cy - thickness / 2
        width: anim.dot.vertical ? thickness : span
        height: anim.dot.vertical ? span : thickness
        radius: thickness / 2
        // Fainter in the middle, so the thread seems to thin between the two drops.
        gradient: Gradient {
            orientation: anim.dot.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(anim.dot.color, 0.85) }
            GradientStop { position: 0.5; color: Qt.alpha(anim.dot.color, 0.3) }
            GradientStop { position: 1; color: Qt.alpha(anim.dot.color, 0.85) }
        }
        visible: pour.running && thickness > 0.3
        antialiasing: true
    }
    Rectangle {
        id: bead
        objectName: "bead"
        readonly property real extent: anim.dot.size * 0.6
        // Eased in and out, so the bead leaves the shrinking dot gently and slows into the growing one.
        readonly property real e: anim.dot.easeInOutQuad(anim.pourT)
        x: anim.fromX + (anim.dot.cx - anim.fromX) * e - extent / 2
        y: anim.fromY + (anim.dot.cy - anim.fromY) * e - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: anim.dot.color
        opacity: Math.min(1, anim.pourT * 8, (1 - anim.pourT) * 8)
        visible: pour.running
        antialiasing: true
    }
    ParallelAnimation {
        id: pour
        SequentialAnimation {
            NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 1.8; easing.type: Easing.InOutSine }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: anim.dot.pill; property: "scale"; value: 0 }
            PauseAnimation { duration: anim.dot.unit * 0.3 }
            NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 1.7; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
        NumberAnimation { target: anim; property: "pourT"; from: 0; to: 1; duration: anim.dot.unit * 1.6 }
    }
}
