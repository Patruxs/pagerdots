// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import "animations" as Animations


Item {
    id: dot

   
    property Item target: null
   
    property string animation: "stretch"
    property real size: 6
    property color color: "black"
   
    property real elongation: 0
   
    property int unit: 200
  
    property bool vertical: false
    property real hopSign: -1

   
    readonly property Animations.DotAnimation anim: loader.item as Animations.DotAnimation
    readonly property bool slides: anim?.kind === "slide"
    
    readonly property int travel: anim?.travel ?? 0
  
    readonly property int leadDuration: anim?.leadDuration ?? unit * 2
    readonly property int leadEasing: anim?.leadEasing ?? Easing.BezierSpline
    readonly property int trailDelay: anim?.trailDelay ?? 0
    readonly property int trailDuration: anim?.trailDuration ?? leadDuration
    readonly property int trailEasing: anim?.trailEasing ?? leadEasing
    readonly property bool tethered: anim?.tethered ?? false
    readonly property real thickness: anim?.thickness ?? size
    readonly property real along: anim?.along ?? 0
    readonly property real across: anim?.across ?? 0
    readonly property real squish: anim?.squish ?? 1
    readonly property real lift: anim?.lift ?? 1
    readonly property real flatten: anim?.flatten ?? 1
    readonly property real fade: anim?.fade ?? 1
    readonly property real extent: anim?.extent ?? 1
    readonly property real keep: anim?.keep ?? 0

   
    readonly property Rectangle pill: pillItem
    readonly property Rectangle ghost: ghostItem

   
    property real cx: 0
    property real cy: 0
    Binding on cx {
        when: dot.target !== null
        value: dot.target ? dot.target.x + dot.target.width / 2 : 0
        restoreMode: Binding.RestoreNone
    }
    Binding on cy {
        when: dot.target !== null
        value: dot.target ? dot.target.y + dot.target.height / 2 : 0
        restoreMode: Binding.RestoreNone
    }
   
    readonly property real room: {
        if (!target) return size;
        const extent = vertical ? target.width : target.height;
        return Math.max(size * 0.8, Math.min(size * 1.05, (extent - size) / 2));
    }
    
    function centreOf(cell) {
        return vertical ? cell.y + cell.height / 2 : cell.x + cell.width / 2;
    }
    function easeInOut(p) {
        return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(2 - 2 * p, 3) / 2;
    }
    function easeInOutQuad(p) {
        return p < 0.5 ? 2 * p * p : 1 - Math.pow(2 - 2 * p, 2) / 2;
    }

   
    property real leadX: cx
    property real leadY: cy
    property real trailX: cx
    property real trailY: cy
    
    readonly property real gap: vertical ? Math.abs(leadY - trailY) : Math.abs(leadX - trailX)
    readonly property real gapStart: vertical ? Math.min(leadY, trailY) : Math.min(leadX, trailX)

   
    readonly property var smoothCurve: [0.2, 0, 0, 1, 1, 1]
   
    function matchedCurve(s) {
        s = isFinite(s) ? Math.max(-1, Math.min(2.8, s)) : 0;
        return [0.35, 0.35 * s, 0.4, 1, 1, 1];
    }

   
    property bool ready: false
    Timer {
        id: settle
        interval: 100
        onTriggered: dot.ready = true
    }

   
    component Mover: Behavior {
        id: mover
        property real current: 0
        property int span: 0
        property bool cutIn: false
        property var curve: dot.smoothCurve
        property bool moving: false
        property real velocity: 0   // of `current`, per ms
        property real last: 0
        property FrameAnimation tracker: FrameAnimation {
            running: mover.moving
            onRunningChanged: {
                mover.last = mover.current;
                if (!running) mover.velocity = 0;
            }
            onTriggered: {
                if (frameTime > 0) mover.velocity = (mover.current - mover.last) / (frameTime * 1000);
                mover.last = mover.current;
                if (Math.abs(mover.current - mover.targetValue) < 0.01 && Math.abs(mover.velocity) < 0.005) {
                    mover.moving = false;
                }
            }
        }
        // Emitted as the new value arrives, before the move in flight is stopped.
        onTargetValueChanged: {
            cutIn = moving;
            curve = cutIn && span > 0 ? dot.matchedCurve(velocity * span / (targetValue - current)) : dot.smoothCurve;
            moving = true;
        }
    }
   
    function easingFor(type, curve) {
        return type === Easing.BezierSpline ? { type: type, bezierCurve: curve }
                                            : { type: type, amplitude: 1, period: 0.45 };
    }
    component LeadAnimation: NumberAnimation {
        property var curve: dot.smoothCurve
        duration: dot.leadDuration
        easing: dot.easingFor(dot.leadEasing, curve)
    }
    component TrailAnimation: SequentialAnimation {
        id: trailAnimation
        property var curve: dot.smoothCurve
        PauseAnimation { duration: dot.trailDelay }
        NumberAnimation {
            duration: dot.trailDuration
            easing: dot.easingFor(dot.trailEasing, trailAnimation.curve)
        }
    }
    Mover on leadX {
        id: leadMoverX
        current: dot.leadX
        span: dot.leadDuration
        enabled: dot.ready && dot.slides
        LeadAnimation { curve: leadMoverX.curve }
    }
    Mover on leadY {
        id: leadMoverY
        current: dot.leadY
        span: dot.leadDuration
        enabled: dot.ready && dot.slides
        LeadAnimation { curve: leadMoverY.curve }
    }
    Mover on trailX {
        id: trailMoverX
        current: dot.trailX
        span: dot.trailDuration
        enabled: dot.ready && dot.slides
        TrailAnimation { curve: trailMoverX.curve }
    }
    Mover on trailY {
        id: trailMoverY
        current: dot.trailY
        span: dot.trailDuration
        enabled: dot.ready && dot.slides
        TrailAnimation { curve: trailMoverY.curve }
    }

   
    property Item shown: null
    onTargetChanged: {
        const old = shown;
        shown = target;
        if (!ready) {
            if (target) settle.restart();
            return;
        }
        if (old && target && old !== target && anim) anim.start(old, target);
    }

   
    Rectangle {
        id: ghostItem
        objectName: "ghost"
        property real baseX: 0
        property real baseY: 0
        property real fall: 0
        property real slide: 0
        property real extent: 1
        property real keep: 0
        readonly property real shift: dot.elongation * (1 - extent) * (keep + 1) / 2
        x: baseX + (dot.vertical ? -fall * dot.hopSign : slide + shift)
        y: baseY + (dot.vertical ? slide + shift : -fall * dot.hopSign)
        width: dot.size + (dot.vertical ? 0 : dot.elongation * extent)
        height: dot.size + (dot.vertical ? dot.elongation * extent : 0)
        radius: dot.size / 2
        color: dot.color
        visible: false
        transformOrigin: Item.Center
        antialiasing: true
    }
   
    function placeGhost(cell, scale = 1) {
        ghostItem.extent = 1;
        ghostItem.keep = 0;
        ghostItem.baseX = cell.x + (cell.width - ghostItem.width) / 2;
        ghostItem.baseY = cell.y + (cell.height - ghostItem.height) / 2;
        ghostItem.fall = 0;
        ghostItem.slide = 0;
        ghostItem.opacity = 1;
        ghostItem.scale = scale;
        ghostItem.visible = true;
    }

   
    Rectangle {
        id: pillItem
        objectName: "pill"
        readonly property real length: (dot.tethered ? 0 : dot.gap) + dot.elongation * dot.extent
        readonly property real start: (dot.tethered ? (dot.vertical ? dot.leadY : dot.leadX) : dot.gapStart)
                                      - dot.elongation * dot.extent / 2
                                      + dot.elongation * (1 - dot.extent) * dot.keep / 2
        x: (dot.vertical ? dot.leadX : start) - dot.thickness / 2
           + (dot.vertical ? dot.across * dot.hopSign : dot.along)
        y: (dot.vertical ? start : dot.leadY) - dot.thickness / 2
           + (dot.vertical ? dot.along : dot.across * dot.hopSign)
        width: (dot.vertical ? 0 : length) + dot.thickness
        height: (dot.vertical ? length : 0) + dot.thickness
        radius: dot.thickness / 2
        color: Qt.alpha(dot.color, dot.fade)
        visible: dot.target !== null
        transformOrigin: Item.Center
        antialiasing: true
        transform: Scale {
            origin.x: pillItem.width / 2
            origin.y: pillItem.height / 2
            xScale: (dot.vertical ? 1 / dot.squish : dot.squish * dot.flatten) * dot.lift
            yScale: (dot.vertical ? dot.squish * dot.flatten : 1 / dot.squish) * dot.lift
        }
    }

   
    Loader {
        id: loader
        anchors.fill: parent
    }
    
    function load() {
        loader.source = "";
        pillItem.opacity = 1;
        pillItem.scale = 1;
        ghostItem.visible = false;
      
        if (animation === "none" || animation === "") return;
        const name = animation.charAt(0).toUpperCase() + animation.slice(1);
        loader.setSource("animations/" + name + ".qml", { dot: dot });
    }
    onAnimationChanged: load()
    Component.onCompleted: load()
}
