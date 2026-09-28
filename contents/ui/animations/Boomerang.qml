// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

DotAnimation {
    id: anim
    kind: "shift"
    along: shift

    property real shift: 0
    property real backTo: 0

    function start(old, target) {
        const c = dot.centreOf(target);
        const span = dot.vertical ? target.height : target.width;
        shift = dot.centreOf(old) + shift - c;
        backTo = dot.centreOf(old) - c + (c > dot.centreOf(old) ? -span : span);
        boomerang.restart();
    }

    SequentialAnimation {
        id: boomerang
        NumberAnimation { target: anim; property: "shift"; to: anim.backTo; duration: anim.dot.unit * 0.8; easing.type: Easing.InOutSine }
        NumberAnimation { target: anim; property: "shift"; to: 0; duration: anim.dot.unit * 1.2; easing.type: Easing.InOutCubic }
    }
}
