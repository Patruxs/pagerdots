// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// "topple": the dot stands up into a short post on the old cell, which topples over
// like a domino towards the new cell, reaching out as it falls so that its tip runs
// along the edge of the panel and comes down on the new cell. The post vanishes as it
// lands, leaving the dot there. The post pivots on the old cell's centre.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.4

    property real postLen: 0
    property real postAngle: 0
    property int phase: 0       // 1 while standing up and falling, 2 while landing
    readonly property real standLen: dot.room + dot.size / 2
    readonly property real toppleDist: dot.vertical ? Math.abs(dot.cy - fromY) : Math.abs(dot.cx - fromX)
    // A quarter turn towards the new cell, from a post that stands the way hopSign points.
    readonly property real toppleAngle: Math.sign(dot.vertical ? dot.cy - fromY : dot.cx - fromX) * 90
                                        * (dot.vertical ? dot.hopSign : -dot.hopSign)

    function start(old, target) {
        if (phase === 1) {
            // Still standing or falling: the post keeps its pivot and falls towards the
            // new cell instead (or stands back up, if that is where the pivot is).
            if (fall.running) fall.restart();
            return;
        }
        fall.stop();
        setFrom(old);
        dot.placeGhost(old);
        postAngle = 0;
        postLen = 0;
        stand.restart();
    }

    Rectangle {
        id: post
        objectName: "post"
        readonly property real thick: Math.max(1.5, anim.dot.size * 0.35)
        // Standing, its own length; falling, as much as keeps the tip inside the panel,
        // up to the new cell (or, cut in on back to the pivot, back to standing).
        readonly property real len: Math.min(Math.max(anim.toppleDist, anim.standLen),
                                             anim.postLen / Math.max(0.05, Math.cos(anim.postAngle * Math.PI / 180)))
        readonly property bool up: anim.dot.hopSign < 0   // stands towards the top or the left
        x: anim.dot.vertical ? (post.up ? anim.fromX - post.len : anim.fromX) : anim.fromX - post.thick / 2
        y: anim.dot.vertical ? anim.fromY - post.thick / 2 : (post.up ? anim.fromY - post.len : anim.fromY)
        width: anim.dot.vertical ? post.len : post.thick
        height: anim.dot.vertical ? post.thick : post.len
        radius: post.thick / 2
        color: anim.dot.color
        transformOrigin: anim.dot.vertical ? (post.up ? Item.Right : Item.Left) : (post.up ? Item.Bottom : Item.Top)
        rotation: anim.postAngle
        visible: false
        antialiasing: true
    }
    SequentialAnimation {
        id: stand
        PropertyAction { target: anim; property: "phase"; value: 1 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PropertyAction { target: post; property: "opacity"; value: 1 }
        PropertyAction { target: post; property: "visible"; value: true }
        ParallelAnimation {
            NumberAnimation { target: anim; property: "postLen"; to: anim.standLen; duration: anim.dot.unit * 0.4; easing.type: Easing.OutQuad }
            NumberAnimation { target: anim.dot.ghost; property: "scale"; to: 0; duration: anim.dot.unit * 0.3; easing.type: Easing.InQuad }
        }
        PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        ScriptAction { script: fall.restart() }
    }
    SequentialAnimation {
        id: fall
        NumberAnimation { target: anim; property: "postAngle"; to: anim.toppleAngle; duration: anim.dot.unit * 0.7; easing.type: Easing.InQuad }
        PropertyAction { target: anim; property: "phase"; value: 2 }
        PropertyAction { target: anim.dot.pill; property: "scale"; value: 0.6 }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        ParallelAnimation {
            NumberAnimation { target: anim.dot.pill; property: "scale"; to: 1; duration: anim.dot.unit * 0.4; easing.type: Easing.OutBack; easing.overshoot: 2 }
            NumberAnimation { target: post; property: "opacity"; to: 0; duration: anim.dot.unit * 0.12 }
        }
        PropertyAction { target: post; property: "visible"; value: false }
        PropertyAction { target: anim; property: "postAngle"; value: 0 }
        PropertyAction { target: anim; property: "postLen"; value: 0 }
        PropertyAction { target: anim; property: "phase"; value: 0 }
    }
}
