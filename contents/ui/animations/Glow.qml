// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "glow": a soft halo blooms around the dot as it sets off and fades once it lands.
DotAnimation {
    id: anim

    function start(old, target) {
        glow.restart();
    }

    Rectangle {
        id: halo
        objectName: "halo"
        readonly property real extent: anim.dot.size * 2.6
        x: anim.dot.leadX - extent / 2
        y: anim.dot.leadY - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: anim.dot.color
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    ParallelAnimation {
        id: glow
        NumberAnimation { target: halo; property: "scale"; from: 0.3; to: 1; duration: anim.leadDuration; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: halo; property: "opacity"; from: 0; to: 0.35; duration: anim.dot.unit * 0.4; easing.type: Easing.OutQuad }
            NumberAnimation { target: halo; property: "opacity"; to: 0; duration: anim.leadDuration * 1.2; easing.type: Easing.InQuad }
        }
    }
}
