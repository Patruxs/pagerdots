// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

DotAnimation {
    id: anim
    kind: "shift"
    travel: dot.unit * 2.2
    along: shift
    fade: {
        const at = (dot.vertical ? dot.cy : dot.cx) + along;
        const extent = dot.vertical ? height : width;
        const margin = dot.size * 2.5;
        return Math.max(0, Math.min(1, (at + dot.size) / margin, (extent + dot.size - at) / margin));
    }

    property real shift: 0
    property real exitAt: 0
    property real exit: 0
    property real entry: 0
    property int phase: 0

    function start(old, target) {
        const c = dot.centreOf(target);
        const extent = dot.vertical ? height : width;
        shift = dot.centreOf(old) + shift - c;
        if ((wrap.running && phase === 2) || enter.running) {
            wrap.stop();
            enter.restart();
            return;
        }

        if (!wrap.running) exitAt = c > dot.centreOf(old) ? -dot.size : extent + dot.size;
        exit = exitAt - c;
        entry = (exitAt < 0 ? extent + dot.size : -dot.size) - c;
        wrap.restart();
    }

    SequentialAnimation {
        id: wrap
        PropertyAction { target: anim; property: "phase"; value: 1 }
        NumberAnimation { target: anim; property: "shift"; to: anim.exit; duration: anim.dot.unit * 0.9; easing.type: Easing.InQuad }
        PropertyAction { target: anim; property: "shift"; value: anim.entry }
        PropertyAction { target: anim; property: "phase"; value: 2 }
        NumberAnimation { target: anim; property: "shift"; to: 0; duration: anim.dot.unit * 1.3; easing.type: Easing.OutQuad }
        PropertyAction { target: anim; property: "phase"; value: 0 }
    }
    NumberAnimation {
        id: enter
        target: anim; property: "shift"; to: 0
        duration: anim.dot.unit * 1.3
        easing.type: Easing.OutQuad
    }
}
