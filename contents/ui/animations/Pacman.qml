// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes

DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 0.55 + crossTime

    property real pacT: 0
    property int dir: 1
    property int cells: 1
    property int pelletCount: 0
    property real pelletStep: 0
    property int crossTime: dot.unit
    readonly property real pacExtent: dot.size * 1.8
    readonly property real pelletExtent: Math.max(2, dot.size * 0.45)
    readonly property real progress: dot.easeInOutQuad(pacT)
    readonly property real pacX: fromX + (dot.cx - fromX) * progress
    readonly property real pacY: fromY + (dot.cy - fromY) * progress
    readonly property real pacAlong: dot.vertical ? pacY : pacX
    readonly property real mouth: 110 * Math.abs(Math.sin(Math.PI * Math.max(2, cells) * progress))

    function pitchOf(target) {
        const span = dot.vertical ? target.height : target.width;
        const centre = dot.centreOf(target);
        let pitch = Infinity;
        const siblings = target.parent?.children ?? [];
        for (let i = 0; i < siblings.length; i++) {
            const sibling = siblings[i];
            if (sibling === target || (dot.vertical ? sibling.height : sibling.width) !== span) continue;
            const distance = Math.abs(dot.centreOf(sibling) - centre);
            if (distance > 0) pitch = Math.min(pitch, distance);
        }
        return Math.max(1, isFinite(pitch) ? pitch : span);
    }

    function start(old, target) {
        const mid = grow.running || cross.running;
        setFrom(old, mid ? progress : 1);
        pacT = 0;
        const c = dot.centreOf(target);
        const from = dot.vertical ? fromY : fromX;
        const pitch = pitchOf(target);
        const distance = Math.abs(c - from);
        dir = c > from ? 1 : -1;
        cells = Math.max(1, Math.round(distance / pitch));
        pelletStep = -dir * pitch;
        pelletCount = Math.min(pellets.count, Math.max(1, Math.ceil((distance - dot.size / 2) / pitch)));
        crossTime = dot.unit * Math.min(1.6, 0.5 + 0.35 * cells);
        if (cross.running) cross.restart();
        else if (!grow.running) grow.restart();
    }

    Repeater {
        id: pellets
        model: 8
        Rectangle {
            id: pellet
            required property int index
            readonly property real at: (anim.dot.vertical ? anim.dot.cy : anim.dot.cx) + anim.pelletStep * pellet.index
            readonly property bool eaten: anim.dir * (anim.pacAlong - pellet.at) > -anim.dot.size * 0.2
            x: (anim.dot.vertical ? anim.dot.cx : pellet.at) - anim.pelletExtent / 2
            y: (anim.dot.vertical ? pellet.at : anim.dot.cy) - anim.pelletExtent / 2
            width: anim.pelletExtent
            height: anim.pelletExtent
            radius: anim.pelletExtent / 2
            color: anim.dot.color
            visible: pellet.index < anim.pelletCount && !pellet.eaten
            antialiasing: true
        }
    }

    Shape {
        id: pac
        objectName: "pacman"
        property real extent: anim.dot.size
        readonly property real r: pac.extent / 2
        x: anim.pacX - pac.r
        y: anim.pacY - pac.r
        width: pac.extent
        height: pac.extent
        rotation: anim.dot.vertical ? (anim.dir > 0 ? 90 : -90) : (anim.dir > 0 ? 0 : 180)
        preferredRendererType: Shape.CurveRenderer
        visible: false

        ShapePath {
            fillColor: anim.dot.color
            strokeColor: "transparent"
            startX: pac.r
            startY: pac.r
            PathAngleArc {
                centerX: pac.r
                centerY: pac.r
                radiusX: pac.r
                radiusY: pac.r
                startAngle: anim.mouth / 2
                sweepAngle: 360 - anim.mouth
            }
            PathLine { x: pac.r; y: pac.r }
        }
    }

    SequentialAnimation {
        id: grow
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 0 }
        PropertyAction { target: pac; property: "visible"; value: true }
        NumberAnimation { target: pac; property: "extent"; to: anim.pacExtent; duration: anim.dot.unit * 0.25; easing.type: Easing.OutQuad }
        ScriptAction { script: cross.restart() }
    }
    SequentialAnimation {
        id: cross
        ParallelAnimation {
            NumberAnimation { target: anim; property: "pacT"; to: 1; duration: anim.crossTime }
            NumberAnimation { target: pac; property: "extent"; to: anim.pacExtent; duration: anim.dot.unit * 0.2 }
        }
        PropertyAction { target: anim; property: "pelletCount"; value: 0 }
        NumberAnimation { target: pac; property: "extent"; to: anim.dot.size; duration: anim.dot.unit * 0.3; easing.type: Easing.InOutQuad }
        PropertyAction { target: anim.dot.pill; property: "opacity"; value: 1 }
        PropertyAction { target: pac; property: "visible"; value: false }
    }
}
