// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "hop": rises and falls in an arc while sliding, then squashes flat on landing.
DotAnimation {
    id: anim
    leadEasing: Easing.InOutSine

    function start(old, target) {
        hop.restart();
    }

    SequentialAnimation {
        id: hop
        NumberAnimation { target: anim; property: "across"; to: anim.dot.room; duration: anim.leadDuration / 2; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "across"; to: 0; duration: anim.leadDuration / 2; easing.type: Easing.InQuad }
        NumberAnimation { target: anim; property: "squish"; to: 1.3; duration: anim.dot.unit * 0.4; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "squish"; to: 1; duration: anim.dot.unit * 0.9; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }
}
