// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import "animations" as Animations

// The current-desktop marker: a single dot that moves from cell to cell with one of
// the animations in animations/ (listed in Animations.js). Fill the parent of the
// cells with it, so that it shares their coordinate space, and point `target` at the
// current cell.
//
// This file holds what every animation shares: the two trackers that carry the dot
// across (with momentum matching when a move cuts in on one still in flight), the
// pill that is the dot itself, the ghost that a swap leaves behind on the old cell,
// and the loading of the current animation. Each animation is a DotAnimation, loaded
// from animations/<Name>.qml, that drives these through the hooks described in
// animations/DotAnimation.qml.
Item {
    id: dot

    // The cell to mark, or null when there is none (its centre is where the dot goes).
    property Item target: null
    // One of the ids in Animations.MODES.
    property string animation: "stretch"
    property real size: 6
    property color color: "black"
    // Base duration in ms; every animation is a multiple of it. Pass Kirigami's
    // longDuration (scaled by the speed setting) so the widget follows the global
    // animation speed setting.
    property int unit: 200
    // Whether the cells run top to bottom rather than left to right, and which way
    // across the row is "up" for the animations: the way "hop" jumps and "drop" falls
    // in from (-1 for up/left, +1 for down/right).
    property bool vertical: false
    property real hopSign: -1

    // The animation in charge, or null for "none".
    readonly property Animations.DotAnimation anim: loader.item as Animations.DotAnimation
    readonly property bool slides: anim?.kind === "slide"
    // How long the dot takes to leave the old cell and settle on the new one, so that
    // whatever is underneath can time its own fade to it.
    readonly property int travel: anim?.travel ?? 0
    // What the animation asks of the shared pieces; see DotAnimation.qml for each.
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

    // The dot itself and the ghost, for the animations to drive.
    readonly property Rectangle pill: pillItem
    readonly property Rectangle ghost: ghostItem

    // Centre of the target. Kept at its last value while there is no target, so the
    // dot does not fly in from the corner when the cells are rebuilt.
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
    // Room across the row: how far the dot can go across it (or a shape reach out)
    // without leaving the cell.
    readonly property real room: {
        if (!target) return size;
        const extent = vertical ? target.width : target.height;
        return Math.max(size * 0.8, (extent - size) / 2);
    }
    // Position of a cell's centre along the row.
    function centreOf(cell) {
        return vertical ? cell.y + cell.height / 2 : cell.x + cell.width / 2;
    }
    function easeInOut(p) {
        return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(2 - 2 * p, 3) / 2;
    }
    function easeInOutQuad(p) {
        return p < 0.5 ? 2 * p * p : 1 - Math.pow(2 - 2 * p, 2) / 2;
    }

    // Two trackers per axis follow the target centre, and the pill spans the gap between
    // them. With equal timing they coincide and the dot simply slides; in "stretch" the
    // lead tracker races ahead while the trail one lags, so the dot elongates into a
    // pill towards the new desktop and then contracts onto it.
    property real leadX: cx
    property real leadY: cy
    property real trailX: cx
    property real trailY: cy
    // The distance between the trackers along the row, and where that stretch starts.
    readonly property real gap: vertical ? Math.abs(leadY - trailY) : Math.abs(leadX - trailX)
    readonly property real gapStart: vertical ? Math.min(leadY, trailY) : Math.min(leadX, trailX)

    // The default curve: a brief ease-in so the dot never jerks off the mark, then a
    // long, gentle deceleration onto the new cell (the "standard" curve of most
    // motion guidelines).
    readonly property var smoothCurve: [0.2, 0, 0, 1, 1, 1]
    // The same curve for a move that cuts in on one still in flight: it sets off at the
    // speed the dot already has (`s`, normalised to the new move's distance and duration)
    // and decelerates from there, so quick switching flows as one motion. Cutting in
    // on a move the other way gives a negative slope, so the dot carries on a little
    // before turning back, as its momentum would have it.
    // The control points are placed so the speed then rises only a little before the
    // long deceleration, rather than peaking mid-move like a fresh start does.
    function matchedCurve(s) {
        s = isFinite(s) ? Math.max(-1, Math.min(2.8, s)) : 0;
        return [0.35, 0.35 * s, 0.4, 1, 1, 1];
    }

    // Animations are enabled only once the first target has been laid out, so the dot
    // does not glide in from the corner when the widget loads.
    property bool ready: false
    Timer {
        id: settle
        interval: 100
        onTriggered: dot.ready = true
    }

    // A Behavior that knows whether the move it is starting cuts in on one still in
    // flight, and how fast the property is moving at that moment, so the animation it
    // runs can carry that speed over (see matchedCurve()). `current` must be bound to
    // the property it drives and `span` to the duration its animation will run for.
    // The speed is measured frame by frame, but only while a move is in flight.
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
    // The amplitude and period only apply to OutElastic, and the curve only to BezierSpline.
    component LeadAnimation: NumberAnimation {
        property var curve: dot.smoothCurve
        duration: dot.leadDuration
        easing.type: dot.leadEasing
        easing.amplitude: 1
        easing.period: 0.45
        easing.bezierCurve: curve
    }
    component TrailAnimation: SequentialAnimation {
        id: trailAnimation
        property var curve: dot.smoothCurve
        PauseAnimation { duration: dot.trailDelay }
        NumberAnimation {
            duration: dot.trailDuration
            easing.type: dot.trailEasing
            easing.amplitude: 1
            easing.period: 0.45
            easing.bezierCurve: trailAnimation.curve
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

    // The cell currently marked, remembered so the animation knows where the move
    // starts from.
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

    // Copy of the dot left on the old cell during a swap, for the animation to fade,
    // shrink or knock away. `fall` moves it across the row, against hopSign (for
    // "drop"), and `slide` along it (for "recoil").
    Rectangle {
        id: ghostItem
        objectName: "ghost"
        property real baseX: 0
        property real baseY: 0
        property real fall: 0
        property real slide: 0
        x: baseX + (dot.vertical ? -fall * dot.hopSign : slide)
        y: baseY + (dot.vertical ? slide : -fall * dot.hopSign)
        width: dot.size
        height: dot.size
        radius: dot.size / 2
        color: dot.color
        visible: false
        transformOrigin: Item.Center
        antialiasing: true
    }
    // Show the ghost, whole and at rest, on `cell`.
    function placeGhost(cell, scale = 1) {
        ghostItem.baseX = cell.x + (cell.width - size) / 2;
        ghostItem.baseY = cell.y + (cell.height - size) / 2;
        ghostItem.fall = 0;
        ghostItem.slide = 0;
        ghostItem.opacity = 1;
        ghostItem.scale = scale;
        ghostItem.visible = true;
    }

    // The dot itself. A capsule while stretched, a circle otherwise.
    Rectangle {
        id: pillItem
        objectName: "pill"
        readonly property real length: dot.tethered ? 0 : dot.gap
        readonly property real start: dot.tethered ? (dot.vertical ? dot.leadY : dot.leadX) : dot.gapStart
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

    // The current animation, drawn over the pill and the ghost. Everything is one
    // colour, so the order makes no visible difference.
    Loader {
        id: loader
        anchors.fill: parent
    }
    // Loading another animation takes the old one's shapes and running animations with
    // it; whatever it may have left half faded or shrunk is put back here.
    function load() {
        loader.source = "";
        pillItem.opacity = 1;
        pillItem.scale = 1;
        ghostItem.visible = false;
        // The id is empty on the settings page until Plasma has handed it the config.
        if (animation === "none" || animation === "") return;
        const name = animation.charAt(0).toUpperCase() + animation.slice(1);
        loader.setSource("animations/" + name + ".qml", { dot: dot });
    }
    onAnimationChanged: load()
    Component.onCompleted: load()
}
