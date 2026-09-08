// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "swing": dips below the row and rises again while sliding, so that with the sine
// easing of the slide the dot swings over on a pendulum's arc.
DotAnimation {
    id: anim
    leadEasing: Easing.InOutSine

    function start(old, target) {
        swing.restart();
    }

    SequentialAnimation {
        id: swing
        NumberAnimation { target: anim; property: "across"; to: -anim.dot.room; duration: anim.leadDuration / 2; easing.type: Easing.OutSine }
        NumberAnimation { target: anim; property: "across"; to: 0; duration: anim.leadDuration / 2; easing.type: Easing.InSine }
    }
}
