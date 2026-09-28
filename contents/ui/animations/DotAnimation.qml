// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import ".." as UI

Item {
    id: base

    required property UI.Dot dot

    property string kind: "slide"

    property int travel: kind === "slide" ? Math.max(leadDuration, trailDelay + trailDuration)
                                          : dot.unit * 2

    property int leadDuration: dot.unit * 2
    property int leadEasing: Easing.BezierSpline
    property int trailDelay: 0
    property int trailDuration: leadDuration
    property int trailEasing: leadEasing
    property bool tethered: false
    property real thickness: dot.size

    property real along: 0
    property real across: 0
    property real squish: 1
    property real lift: 1
    property real flatten: 1
    property real fade: 1
    property real extent: 1
    property real keep: 0

    property real fromX: 0
    property real fromY: 0

    function setFrom(old, progress = 1) {
        fromX += (old.x + old.width / 2 - fromX) * progress;
        fromY += (old.y + old.height / 2 - fromY) * progress;
    }

    function start(old, target) {}

    anchors.fill: parent
}
