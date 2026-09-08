// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "flash": no motion at all; the dot shows up on the new cell and blinks twice.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.3

    function start(old, target) {
        flash.restart();
    }

    SequentialAnimation {
        id: flash
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        PauseAnimation { duration: anim.dot.unit * 0.3 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PauseAnimation { duration: anim.dot.unit * 0.25 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        PauseAnimation { duration: anim.dot.unit * 0.3 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PauseAnimation { duration: anim.dot.unit * 0.25 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
    }
}
