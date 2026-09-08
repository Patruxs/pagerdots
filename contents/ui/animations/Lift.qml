// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "lift": the dot is picked up, grows as it is carried over, and is set down again.
DotAnimation {
    id: anim
    leadDuration: dot.unit * 2.25

    function start(old, target) {
        carry.restart();
    }

    SequentialAnimation {
        id: carry
        NumberAnimation { target: anim; property: "lift"; to: 1.5; duration: anim.leadDuration * 0.45; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "lift"; to: 0.92; duration: anim.leadDuration * 0.55; easing.type: Easing.InQuad }
        NumberAnimation { target: anim; property: "lift"; to: 1; duration: anim.dot.unit * 0.8; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }
}
