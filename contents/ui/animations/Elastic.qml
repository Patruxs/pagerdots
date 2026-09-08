// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "elastic": the dot stays round and is tethered to the old cell by a thin band that
// spans the gap between the trackers, stays taut, then snaps in; the dot wobbles from
// the impact.
DotAnimation {
    id: anim
    leadDuration: dot.unit * 1.5
    trailDuration: dot.unit * 2.5
    trailEasing: Easing.InQuart
    tethered: true

    function start(old, target) {
        wobble.restart();
    }

    Rectangle {
        id: band
        objectName: "band"
        readonly property real thickness: Math.max(1.5, anim.dot.size * 0.35)
        x: anim.dot.vertical ? anim.dot.leadX - thickness / 2 : anim.dot.gapStart
        y: anim.dot.vertical ? anim.dot.gapStart : anim.dot.leadY - thickness / 2
        width: anim.dot.vertical ? thickness : anim.dot.gap
        height: anim.dot.vertical ? anim.dot.gap : thickness
        radius: thickness / 2
        color: anim.dot.color
        opacity: 0.9
        visible: anim.dot.target !== null
        antialiasing: true
    }
    // Once the band has snapped back into the dot, the dot wobbles from the impact.
    SequentialAnimation {
        id: wobble
        PauseAnimation { duration: anim.trailDuration * 0.85 }
        NumberAnimation { target: anim; property: "squish"; to: 1.35; duration: anim.dot.unit * 0.3; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "squish"; to: 1; duration: anim.dot.unit * 1.8; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
    }
}
