// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "ripple": a ring spreads out from the new cell as the dot lands on it.
DotAnimation {
    id: anim

    function start(old, target) {
        ripple.restart();
    }

    Rectangle {
        id: ring
        objectName: "ring"
        property real extent: anim.dot.size
        x: anim.dot.cx - extent / 2
        y: anim.dot.cy - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: "transparent"
        border.color: anim.dot.color
        border.width: Math.max(1, anim.dot.size / 4)
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    SequentialAnimation {
        id: ripple
        PauseAnimation { duration: anim.leadDuration * 0.45 }
        ParallelAnimation {
            NumberAnimation { target: ring; property: "extent"; from: anim.dot.size; to: anim.dot.size * 3.5; duration: anim.dot.unit * 2.5; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring; property: "opacity"; from: 0.7; to: 0; duration: anim.dot.unit * 2.5; easing.type: Easing.InQuad }
        }
    }
}
