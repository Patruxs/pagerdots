// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick

// The current-desktop marker: a single dot that moves from cell to cell with one
// of several animations (see Animations.js). Fill the parent of the cells with it,
// so that it shares their coordinate space, and point `target` at the current cell.
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
    // across the row "hop" jumps and "drop" falls in from (-1 for up/left, +1 for down/right).
    property bool vertical: false
    property real hopSign: -1

    // "pop", "fade", "drop", "sparks", "pour", "ring", "beam", "split" and "flash" swap
    // the dot in place; "wrap", "steps" and "boomerang" move it along the row on a path
    // of their own (see `shift`); everything else slides it across the panel.
    readonly property bool swaps: animation === "pop" || animation === "fade"
                                  || animation === "drop" || animation === "sparks"
                                  || animation === "pour" || animation === "ring"
                                  || animation === "beam" || animation === "split"
                                  || animation === "flash"
    readonly property bool shifts: animation === "wrap" || animation === "steps"
                                   || animation === "boomerang"
    readonly property bool slides: !swaps && !shifts && animation !== "none"
    // "elastic" keeps the dot round and draws the gap between the two trackers (see
    // below) as a separate band rather than stretching the dot.
    readonly property bool tethered: animation === "elastic"
    // "zip" thins the pill the further it is stretched, so it streaks across as a fine line.
    readonly property bool zips: animation === "zip"
    // How long the dot takes to leave the old cell and settle on the new one, so that
    // whatever is underneath can time its own fade to it.
    readonly property int travel: slides ? Math.max(leadDuration, trailDelay + trailDuration)
                                : sparks ? unit * 2.4
                                : animation === "wrap" ? unit * 2.2
                                : animation === "flash" ? unit * 1.3
                                : unit * 2

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

    // Two trackers per axis follow the target centre, and the pill spans the gap between
    // them. With equal timing they coincide and the dot simply slides; in "stretch" the
    // lead tracker races ahead while the trail one lags, so the dot elongates into a
    // pill towards the new desktop and then contracts onto it. "elastic" draws the gap
    // as a band instead.
    property real leadX: cx
    property real leadY: cy
    property real trailX: cx
    property real trailY: cy

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

    readonly property int leadDuration: {
        switch (animation) {
        case "stretch": return unit * 1.5;
        case "elastic": return unit * 1.5;
        case "zip":     return unit * 1.25;
        case "lift":    return unit * 2.25;
        case "spring":  return unit * 2.75;
        default:        return unit * 2;
        }
    }
    readonly property int leadEasing: {
        switch (animation) {
        case "spring": return Easing.OutElastic;
        case "hop":    return Easing.InOutSine;
        case "zip":    return Easing.OutExpo;   // off like a shot, then coasts in
        case "swing":  return Easing.InOutSine; // with the dip below, a pendulum's arc
        default:       return Easing.BezierSpline;
        }
    }
    // "zip" holds the trail on the old cell until the lead is well away, so the line
    // is drawn out before it is reeled in.
    readonly property int trailDelay: zips ? unit * 0.2 : 0
    readonly property int trailDuration: {
        switch (animation) {
        case "stretch": return unit * 2.25;
        case "elastic": return unit * 2.5;
        case "zip":     return unit * 1.3;
        default:        return leadDuration;
        }
    }
    readonly property int trailEasing: {
        switch (animation) {
        case "stretch": return Easing.InOutQuart;
        case "elastic": return Easing.InQuart;    // the band stays taut, then snaps in
        case "zip":     return Easing.InOutExpo;
        default:        return leadEasing;
        }
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

    // Extra flourishes layered on top of the slide, driven by the animations below.
    property real hop: 0        // offset across the row while hopping, swinging or dropping in
    property real hopLift: 0    // how high the current hop goes, or how far the drop falls
    property real squish: 1     // scale along the row; the dot thins across it to compensate
    property real lift: 1       // uniform scale while "lift" carries the dot over
    // Offset along the row for the modes that move the dot on a path of their own
    // ("wrap", "steps" and "boomerang"): the trackers sit on the new cell at once, and
    // the dot is drawn this far from them. A move starts by setting it to the old
    // cell's distance, so the dot stays put, and the animation brings it to 0.
    property real shift: 0
    // "steps": the same offset, quantised into a few stops (see stepsAnim).
    property real stepFrom: 0
    property real stepT: 0
    property int stepCount: 3
    readonly property real stepShift: animation === "steps"
                                      ? stepFrom * (1 - Math.ceil(stepT * stepCount) / stepCount) : 0
    readonly property real along: shift + stepShift
    // "wrap": the dot fades out as it leaves the row past its end, and in as it re-enters.
    readonly property real edgeFade: {
        if (animation !== "wrap") return 1;
        const at = (vertical ? cy : cx) + along;
        const extent = vertical ? height : width;
        const margin = size * 2.5;
        return Math.max(0, Math.min(1, (at + size) / margin, (extent + size - at) / margin));
    }
    function centreOf(cell) {
        return vertical ? cell.y + cell.height / 2 : cell.x + cell.width / 2;
    }
    function easeInOut(p) {
        return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(2 - 2 * p, 3) / 2;
    }

    // The cell currently marked, remembered so a swap can leave a ghost behind on it.
    property Item shown: null
    onTargetChanged: {
        const old = shown;
        shown = target;
        if (!ready) {
            if (target) settle.restart();
            return;
        }
        if (!old || !target || old === target) return;
        // Room to hop or fall within the cell without leaving it.
        const across = vertical ? target.width : target.height;
        hopLift = Math.max(size * 0.8, (across - size) / 2);
        switch (animation) {
        case "pop":
        case "fade":
            placeGhost(old);
            swap.restart();
            break;
        case "drop":
            placeGhost(old);
            dropAnim.restart();
            break;
        case "swing":
            swingAnim.restart();
            break;
        case "pour":
            placeGhost(old);
            fromX = old.x + old.width / 2;
            fromY = old.y + old.height / 2;
            pourAnim.restart();
            break;
        case "ring": {
            fromX = old.x + old.width / 2;
            fromY = old.y + old.height / 2;
            // Cutting in while a ring is still closing on the old cell: open back out
            // from wherever it got to, rather than from a dot that was never there.
            const closing = ringAnim.running;
            irisOut.extent = closing ? irisIn.extent : size;
            irisOut.fill = closing ? irisIn.fill : 1;
            irisOut.opacity = closing ? irisIn.opacity : 1;
            ringAnim.restart();
            break;
        }
        case "footprints": {
            // One print on the old cell and one on every cell between it and the new
            // one, a cell's width apart, since all the cells are the same size.
            const along = vertical ? target.y - old.y : target.x - old.x;
            const span = vertical ? target.height : target.width;
            printCount = 0;
            printStep = span * (along < 0 ? -1 : 1);
            printFrom = vertical ? old.y + old.height / 2 : old.x + old.width / 2;
            printCount = Math.min(prints.count, Math.max(1, Math.round(Math.abs(along) / Math.max(1, span))));
            break;
        }
        case "ripple":
            ripple.restart();
            break;
        case "hop":
            hopAnim.restart();
            break;
        case "lift":
            liftAnim.restart();
            break;
        case "elastic":
            elasticAnim.restart();
            break;
        case "glow":
            glowAnim.restart();
            break;
        case "sparks":
            placeGhost(old);
            sparksFromX = old.x + old.width / 2;
            sparksFromY = old.y + old.height / 2;
            sparksToX = target.x + target.width / 2;
            sparksToY = target.y + target.height / 2;
            sparksAnim.restart();
            break;
        case "beam": {
            fromX = old.x + old.width / 2;
            fromY = old.y + old.height / 2;
            // Cutting in while a beam is still collapsing on the old cell: beam back out
            // from that, rather than from a dot that was never there.
            const mid = beamAnim.running;
            beamOut.reach = mid ? beamIn.reach : size;
            beamOut.thick = mid ? beamIn.thick : size;
            beamOut.opacity = mid ? beamIn.opacity : 1;
            beamAnim.restart();
            break;
        }
        case "split": {
            // Cutting in mid-flight: the halves set off again from where they are.
            const mid = splitAnim.running;
            const e = mid ? easeInOut(splitT) : 0;
            const ox = old.x + old.width / 2;
            const oy = old.y + old.height / 2;
            splitFromX = mid ? splitFromX + (ox - splitFromX) * e : ox;
            splitFromY = mid ? splitFromY + (oy - splitFromY) * e : oy;
            splitGhost = !mid;
            if (!mid) placeGhost(old);
            splitAnim.restart();
            break;
        }
        case "flash":
            flashAnim.restart();
            break;
        case "wrap": {
            const c = centreOf(target);
            const extent = vertical ? height : width;
            shift = centreOf(old) + along - c;
            if ((wrapAnim.running && wrapPhase === 2) || wrapEnter.running) {
                // Already back on the row: just carry on to the new cell.
                wrapAnim.stop();
                wrapEnter.restart();
                break;
            }
            // Leave by the end away from the new cell (still the same end if the dot is
            // already on its way out) and come back in by the other.
            if (!wrapAnim.running) wrapExitAt = c > centreOf(old) ? -size : extent + size;
            wrapExit = wrapExitAt - c;
            wrapEntry = (wrapExitAt < 0 ? extent + size : -size) - c;
            wrapAnim.restart();
            break;
        }
        case "steps": {
            const c = centreOf(target);
            const span = vertical ? target.height : target.width;
            stepFrom = centreOf(old) + along - c;
            stepT = 0;
            // Three stops for a one-cell move, and one more for every cell beyond that.
            stepCount = Math.min(6, 2 + Math.max(1, Math.round(Math.abs(stepFrom) / Math.max(1, span))));
            stepsAnim.restart();
            break;
        }
        case "boomerang": {
            const c = centreOf(target);
            const span = vertical ? target.height : target.width;
            shift = centreOf(old) + along - c;
            // A whole cell beyond the old one, away from the new one.
            backTo = centreOf(old) - c + (c > centreOf(old) ? -span : span);
            boomerangAnim.restart();
            break;
        }
        }
    }
    function placeGhost(cell) {
        ghost.baseX = cell.x + (cell.width - size) / 2;
        ghost.baseY = cell.y + (cell.height - size) / 2;
        ghost.fall = 0;
    }
    // A mode change mid-animation must not leave the dot half faded, squashed or lifted.
    onAnimationChanged: {
        swap.stop();
        dropAnim.stop();
        ripple.stop();
        hopAnim.stop();
        liftAnim.stop();
        elasticAnim.stop();
        glowAnim.stop();
        sparksAnim.stop();
        swingAnim.stop();
        ringAnim.stop();
        pourAnim.stop();
        beamAnim.stop();
        splitAnim.stop();
        flashAnim.stop();
        wrapAnim.stop();
        wrapEnter.stop();
        stepsAnim.stop();
        boomerangAnim.stop();
        ghost.visible = false;
        irisOut.visible = false;
        irisIn.visible = false;
        beamOut.visible = false;
        beamIn.visible = false;
        ring.opacity = 0;
        halo.opacity = 0;
        pill.opacity = 1;
        pill.scale = 1;
        hop = 0;
        squish = 1;
        lift = 1;
        pourT = 0;
        swarmT = 0;
        splitT = 0;
        spread = 0;
        shift = 0;
        stepFrom = 0;
        stepT = 0;
        wrapPhase = 0;
        printCount = 0;
    }

    // "footprints": a faint print is left on each cell as the dot passes over it and
    // fades away behind it. The prints are laid out from the old cell towards the new
    // one when the move starts, and each shows itself once the dot has gone by.
    property real printFrom: 0
    property real printStep: 0
    property int printCount: 0
    Repeater {
        id: prints
        model: 8
        Rectangle {
            id: mark
            required property int index
            readonly property real extent: dot.size * 0.85
            readonly property real at: dot.printFrom + dot.printStep * index
            readonly property real head: dot.vertical ? dot.leadY : dot.leadX
            // Gone by: the dot has moved on from this cell in the direction of travel.
            readonly property bool passed: index < dot.printCount
                                           && (dot.printStep > 0 ? head > at + dot.size * 0.6
                                                                 : head < at - dot.size * 0.6)
            x: (dot.vertical ? dot.cx : at) - extent / 2
            y: (dot.vertical ? at : dot.cy) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: dot.color
            opacity: 0
            visible: dot.animation === "footprints" && opacity > 0
            antialiasing: true
            onPassedChanged: if (passed) printFade.restart()
            SequentialAnimation {
                id: printFade
                PropertyAction { target: mark; property: "opacity"; value: 0.5 }
                NumberAnimation { target: mark; property: "opacity"; to: 0; duration: dot.unit * 3; easing.type: Easing.InQuad }
            }
        }
    }

    // "glow": a soft halo that blooms around the dot as it sets off and fades once it lands.
    Rectangle {
        id: halo
        objectName: "halo"
        readonly property real extent: dot.size * 2.6
        x: dot.leadX - extent / 2
        y: dot.leadY - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: dot.color
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    ParallelAnimation {
        id: glowAnim
        NumberAnimation { target: halo; property: "scale"; from: 0.3; to: 1; duration: dot.leadDuration; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: halo; property: "opacity"; from: 0; to: 0.35; duration: dot.unit * 0.4; easing.type: Easing.OutQuad }
            NumberAnimation { target: halo; property: "opacity"; to: 0; duration: dot.leadDuration * 1.2; easing.type: Easing.InQuad }
        }
    }

    // "ripple": a ring that spreads out from the new cell as the dot lands on it.
    Rectangle {
        id: ring
        objectName: "ring"
        property real extent: dot.size
        x: dot.cx - extent / 2
        y: dot.cy - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: "transparent"
        border.color: dot.color
        border.width: Math.max(1, dot.size / 4)
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    SequentialAnimation {
        id: ripple
        PauseAnimation { duration: dot.leadDuration * 0.45 }
        ParallelAnimation {
            NumberAnimation { target: ring; property: "extent"; from: dot.size; to: dot.size * 3.5; duration: dot.unit * 2.5; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring; property: "opacity"; from: 0.7; to: 0; duration: dot.unit * 2.5; easing.type: Easing.InQuad }
        }
    }

    // Geometry shared by the pill and the band: the distance between the trackers
    // along the row, and where that stretch starts.
    readonly property real gap: vertical ? Math.abs(leadY - trailY) : Math.abs(leadX - trailX)
    readonly property real gapStart: vertical ? Math.min(leadY, trailY) : Math.min(leadX, trailX)
    // Thickness of the pill across the row: the dot's size, except that "zip" thins it
    // the further it is stretched, so it streaks across as a fine line.
    readonly property real thickness: zips ? size * (1 - 0.55 * Math.min(1, gap / (size * 4))) : size

    // "elastic": the span between the trail and lead trackers, drawn as a thin band
    // tethering the dot to the old cell. It vanishes once the trackers meet.
    Rectangle {
        id: band
        objectName: "band"
        readonly property real thickness: Math.max(1.5, dot.size * 0.35)
        visible: dot.tethered && dot.target !== null
        x: dot.vertical ? dot.leadX - thickness / 2 : dot.gapStart
        y: dot.vertical ? dot.gapStart : dot.leadY - thickness / 2
        width: dot.vertical ? thickness : dot.gap
        height: dot.vertical ? dot.gap : thickness
        radius: thickness / 2
        color: dot.color
        opacity: 0.9
        antialiasing: true
    }

    // "sparks": the dot bursts into a handful of sparks that fly across to the new
    // desktop, each on its own arc and a little behind the last, and gather into a new
    // dot there. `swarmT` runs from 0 to 1 over the whole flight, and each spark takes
    // its own staggered slice of it.
    readonly property bool sparks: animation === "sparks"
    property real swarmT: 0
    property real sparksFromX: 0
    property real sparksFromY: 0
    property real sparksToX: 0
    property real sparksToY: 0
    Repeater {
        model: 6
        Rectangle {
            id: spark
            required property int index
            readonly property int count: 6
            // This spark's progress, 0 to 1, and the same eased in and out.
            readonly property real p: Math.max(0, Math.min(1, (dot.swarmT - index / count * 0.35) / 0.65))
            readonly property real e: p < 0.5 ? 4 * p * p * p : 1 - Math.pow(2 - 2 * p, 3) / 2
            // How far out the arc swings, alternating sides and varying from spark to spark.
            readonly property real reach: (index % 2 ? 1 : -1) * dot.hopLift * (0.4 + 0.6 * ((index * 5) % count) / count)
            readonly property real across: reach * Math.sin(Math.PI * e)
            readonly property real extent: dot.size * (0.4 + 0.3 * ((index * 7) % count) / count)
            x: dot.sparksFromX + (dot.sparksToX - dot.sparksFromX) * e + (dot.vertical ? across : 0) - extent / 2
            y: dot.sparksFromY + (dot.sparksToY - dot.sparksFromY) * e + (dot.vertical ? 0 : across) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: dot.color
            // Fades in as it leaves the old dot and out as it merges into the new one.
            opacity: Math.min(1, p * 5, (1 - p) * 5)
            visible: dot.sparks && sparksAnim.running
            antialiasing: true
        }
    }

    // Centre of the old cell, for the swaps that draw something between the two cells.
    property real fromX: 0
    property real fromY: 0

    // "ring": the dot on the old cell opens out into a ring that spreads and fades, while
    // a ring closes in on the new cell and fills to become the dot. `fill` is how solid
    // the disc inside the ring is: 1 for a dot, 0 for a bare ring.
    component Iris: Rectangle {
        property real extent: dot.size
        property real fill: 1
        width: extent
        height: extent
        radius: extent / 2
        color: Qt.alpha(dot.color, fill)
        border.color: dot.color
        border.width: Math.max(1, dot.size / 4)
        visible: false
        antialiasing: true
    }
    Iris {
        id: irisOut
        objectName: "irisOut"
        x: dot.fromX - extent / 2
        y: dot.fromY - extent / 2
    }
    Iris {
        id: irisIn
        objectName: "irisIn"
        x: dot.cx - extent / 2
        y: dot.cy - extent / 2
    }
    ParallelAnimation {
        id: ringAnim
        // The opening ring starts from whatever onTargetChanged set it to.
        SequentialAnimation {
            PropertyAction { target: irisOut; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: irisOut; property: "fill"; to: 0; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: irisOut; property: "extent"; to: dot.size * 2.6; duration: dot.unit * 1.5; easing.type: Easing.OutCubic }
                NumberAnimation { target: irisOut; property: "opacity"; to: 0; duration: dot.unit * 1.5; easing.type: Easing.InQuad }
            }
            PropertyAction { target: irisOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "opacity"; value: 0 }
            PropertyAction { target: irisIn; property: "extent"; value: dot.size * 2.6 }
            PropertyAction { target: irisIn; property: "fill"; value: 0 }
            PropertyAction { target: irisIn; property: "opacity"; value: 0 }
            PropertyAction { target: irisIn; property: "visible"; value: true }
            PauseAnimation { duration: dot.unit * 0.25 }
            ParallelAnimation {
                NumberAnimation { target: irisIn; property: "opacity"; to: 1; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: irisIn; property: "extent"; to: dot.size; duration: dot.unit * 1.5; easing.type: Easing.InOutCubic }
                SequentialAnimation {
                    PauseAnimation { duration: dot.unit * 0.9 }
                    NumberAnimation { target: irisIn; property: "fill"; to: 1; duration: dot.unit * 0.6; easing.type: Easing.InQuad }
                }
            }
            PropertyAction { target: pill; property: "opacity"; value: 1 }
            PropertyAction { target: irisIn; property: "visible"; value: false }
        }
    }

    // "pour": the dot drains from the old cell into the new one. The ghost shrinks on the
    // old cell as the dot grows on the new one, joined by a thin stream that is thickest
    // while the two are the same size, and a bead runs down the stream to show the flow.
    readonly property bool pours: animation === "pour"
    property real pourT: 0
    Rectangle {
        id: stream
        objectName: "stream"
        readonly property real flow: Math.sqrt(Math.max(0, 4 * ghost.scale * pill.scale))
        readonly property real thickness: Math.max(1, dot.size * 0.3) * Math.min(1, flow)
        readonly property real span: dot.vertical ? Math.abs(dot.cy - dot.fromY) : Math.abs(dot.cx - dot.fromX)
        x: dot.vertical ? dot.cx - thickness / 2 : Math.min(dot.cx, dot.fromX)
        y: dot.vertical ? Math.min(dot.cy, dot.fromY) : dot.cy - thickness / 2
        width: dot.vertical ? thickness : span
        height: dot.vertical ? span : thickness
        radius: thickness / 2
        // Fainter in the middle, so the thread seems to thin between the two drops.
        gradient: Gradient {
            orientation: dot.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha(dot.color, 0.85) }
            GradientStop { position: 0.5; color: Qt.alpha(dot.color, 0.3) }
            GradientStop { position: 1; color: Qt.alpha(dot.color, 0.85) }
        }
        visible: dot.pours && pourAnim.running && thickness > 0.3
        antialiasing: true
    }
    Rectangle {
        id: bead
        objectName: "bead"
        readonly property real extent: dot.size * 0.6
        // Eased in and out, so the bead leaves the shrinking dot gently and slows into the growing one.
        readonly property real e: dot.pourT < 0.5 ? 2 * dot.pourT * dot.pourT : 1 - Math.pow(-2 * dot.pourT + 2, 2) / 2
        x: dot.fromX + (dot.cx - dot.fromX) * e - extent / 2
        y: dot.fromY + (dot.cy - dot.fromY) * e - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: dot.color
        opacity: Math.min(1, dot.pourT * 8, (1 - dot.pourT) * 8)
        visible: dot.pours && pourAnim.running
        antialiasing: true
    }
    ParallelAnimation {
        id: pourAnim
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            NumberAnimation { target: ghost; property: "scale"; to: 0; duration: dot.unit * 1.8; easing.type: Easing.InOutSine }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "scale"; value: 0 }
            PauseAnimation { duration: dot.unit * 0.3 }
            NumberAnimation { target: pill; property: "scale"; to: 1; duration: dot.unit * 1.7; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
        NumberAnimation { target: dot; property: "pourT"; from: 0; to: 1; duration: dot.unit * 1.6 }
    }

    // Copy of the dot left on the old cell during a swap, animating out. `fall` moves
    // it across the row, away from where "hop" jumps to (for "drop").
    Rectangle {
        id: ghost
        objectName: "ghost"
        property real baseX: 0
        property real baseY: 0
        property real fall: 0
        x: baseX + (dot.vertical ? -fall * dot.hopSign : 0)
        y: baseY + (dot.vertical ? 0 : -fall * dot.hopSign)
        width: dot.size
        height: dot.size
        radius: dot.size / 2
        color: dot.color
        visible: false
        transformOrigin: Item.Center
        antialiasing: true
    }

    // The dot itself. A capsule while stretched, a circle otherwise.
    Rectangle {
        id: pill
        objectName: "pill"
        readonly property real length: dot.tethered ? 0 : dot.gap
        readonly property real start: dot.tethered ? (dot.vertical ? dot.leadY : dot.leadX) : dot.gapStart
        x: (dot.vertical ? dot.leadX : start) - dot.thickness / 2
           + (dot.vertical ? dot.hop * dot.hopSign : dot.along)
        y: (dot.vertical ? start : dot.leadY) - dot.thickness / 2
           + (dot.vertical ? dot.along : dot.hop * dot.hopSign)
        width: (dot.vertical ? 0 : length) + dot.thickness
        height: (dot.vertical ? length : 0) + dot.thickness
        radius: dot.thickness / 2
        color: Qt.alpha(dot.color, dot.edgeFade)
        visible: dot.target !== null
        transformOrigin: Item.Center
        antialiasing: true
        transform: Scale {
            origin.x: pill.width / 2
            origin.y: pill.height / 2
            xScale: (dot.vertical ? 1 / dot.squish : dot.squish) * dot.lift
            yScale: (dot.vertical ? dot.squish : 1 / dot.squish) * dot.lift
        }
    }

    // "hop": rise and fall in an arc while sliding, then squash flat on landing.
    SequentialAnimation {
        id: hopAnim
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift; duration: dot.leadDuration / 2; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration / 2; easing.type: Easing.InQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1.3; duration: dot.unit * 0.4; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 0.9; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    // "swing": dip below the row and rise again while sliding, so that with the sine
    // easing of the slide the dot swings over on a pendulum's arc.
    SequentialAnimation {
        id: swingAnim
        NumberAnimation { target: dot; property: "hop"; to: -dot.hopLift; duration: dot.leadDuration / 2; easing.type: Easing.OutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration / 2; easing.type: Easing.InSine }
    }

    // "lift": the dot is picked up, grows as it is carried over, and is set down again.
    SequentialAnimation {
        id: liftAnim
        NumberAnimation { target: dot; property: "lift"; to: 1.5; duration: dot.leadDuration * 0.45; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "lift"; to: 0.92; duration: dot.leadDuration * 0.55; easing.type: Easing.InQuad }
        NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.unit * 0.8; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    // "elastic": once the band has snapped back into the dot, the dot wobbles from the impact.
    SequentialAnimation {
        id: elasticAnim
        PauseAnimation { duration: dot.trailDuration * 0.85 }
        NumberAnimation { target: dot; property: "squish"; to: 1.35; duration: dot.unit * 0.3; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 1.8; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
    }

    // "sparks": the ghost shrinks away as the sparks leave it, they fly across (see the
    // Repeater above), and the dot grows on the new cell as they arrive.
    ParallelAnimation {
        id: sparksAnim
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            NumberAnimation { target: ghost; property: "scale"; from: 1; to: 0; duration: dot.unit * 0.6; easing.type: Easing.InCubic }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: dot; property: "swarmT"; from: 0; to: 1; duration: dot.unit * 2.4 }
        SequentialAnimation {
            PropertyAction { target: pill; property: "scale"; value: 0 }
            PauseAnimation { duration: dot.unit * 1.5 }
            NumberAnimation { target: pill; property: "scale"; from: 0; to: 1; duration: dot.unit * 1.2; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
        }
    }

    // "pop": the ghost shrinks away while the dot springs up on the new cell.
    // "fade": the two cross-fade.
    ParallelAnimation {
        id: swap
        readonly property bool fading: dot.animation === "fade"

        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            NumberAnimation {
                target: ghost
                property: swap.fading ? "opacity" : "scale"
                from: 1; to: 0
                duration: swap.fading ? dot.unit * 1.25 : dot.unit * 0.75
                easing.type: swap.fading ? Easing.OutCubic : Easing.InCubic
            }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        NumberAnimation {
            target: pill
            property: swap.fading ? "opacity" : "scale"
            from: 0; to: 1
            duration: swap.fading ? dot.unit * 1.25 : dot.unit * 1.5
            easing.type: swap.fading ? Easing.OutCubic : Easing.OutBack
            easing.overshoot: 2.5
        }
    }

    // "drop": the ghost falls away off the old cell while a new dot drops onto the
    // new one, landing with a small bounce.
    ParallelAnimation {
        id: dropAnim
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: ghost; property: "fall"; from: 0; to: dot.hopLift * 1.2; duration: dot.unit; easing.type: Easing.InQuad }
                NumberAnimation { target: ghost; property: "opacity"; from: 1; to: 0; duration: dot.unit; easing.type: Easing.InQuad }
            }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: pill; property: "opacity"; from: 0; to: 1; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
        SequentialAnimation {
            NumberAnimation { target: dot; property: "hop"; from: dot.hopLift * 1.2; to: 0; duration: dot.unit * 0.9; easing.type: Easing.InQuad }
            NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.3; duration: dot.unit * 0.35; easing.type: Easing.OutQuad }
            NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.unit * 0.35; easing.type: Easing.InQuad }
        }
    }

    // "beam": the dot on the old cell stretches across the row into a tall thin bar that
    // fades away, while a bar appears on the new cell and collapses into the dot.
    component Beam: Rectangle {
        id: beam
        property real reach: dot.size   // extent across the row
        property real thick: dot.size   // thickness along it
        width: dot.vertical ? beam.reach : beam.thick
        height: dot.vertical ? beam.thick : beam.reach
        radius: Math.min(beam.width, beam.height) / 2
        color: dot.color
        visible: false
        antialiasing: true
    }
    Beam {
        id: beamOut
        objectName: "beamOut"
        x: dot.fromX - width / 2
        y: dot.fromY - height / 2
    }
    Beam {
        id: beamIn
        objectName: "beamIn"
        x: dot.cx - width / 2
        y: dot.cy - height / 2
    }
    readonly property real beamReach: dot.hopLift * 2 + dot.size
    readonly property real beamThick: Math.max(1.5, dot.size * 0.3)
    ParallelAnimation {
        id: beamAnim
        // The outgoing beam starts from whatever onTargetChanged set it to.
        SequentialAnimation {
            PropertyAction { target: beamOut; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: beamOut; property: "reach"; to: dot.beamReach; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: beamOut; property: "thick"; to: dot.beamThick; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
            }
            NumberAnimation { target: beamOut; property: "opacity"; to: 0; duration: dot.unit * 0.7; easing.type: Easing.InQuad }
            PropertyAction { target: beamOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "opacity"; value: 0 }
            PropertyAction { target: beamIn; property: "reach"; value: dot.beamReach }
            PropertyAction { target: beamIn; property: "thick"; value: dot.beamThick }
            PropertyAction { target: beamIn; property: "opacity"; value: 0 }
            PropertyAction { target: beamIn; property: "visible"; value: true }
            PauseAnimation { duration: dot.unit * 0.4 }
            NumberAnimation { target: beamIn; property: "opacity"; to: 1; duration: dot.unit * 0.4; easing.type: Easing.OutQuad }
            PauseAnimation { duration: dot.unit * 0.2 }
            ParallelAnimation {
                NumberAnimation { target: beamIn; property: "reach"; to: dot.size; duration: dot.unit * 0.6; easing.type: Easing.InOutQuad }
                NumberAnimation { target: beamIn; property: "thick"; to: dot.size; duration: dot.unit * 0.6; easing.type: Easing.InOutQuad }
            }
            PropertyAction { target: pill; property: "opacity"; value: 1 }
            PropertyAction { target: beamIn; property: "visible"; value: false }
        }
    }

    // "split": the dot divides into two half-size dots that swing out to either side of
    // the row, travel across, and merge again on the new cell. `splitT` is the progress
    // along the row and `spread` how far apart the halves are.
    readonly property bool splitting: animation === "split"
    property real splitT: 0
    property real spread: 0
    property real splitFromX: 0
    property real splitFromY: 0
    property bool splitGhost: true
    Repeater {
        model: 2
        Rectangle {
            id: half
            required property int index
            readonly property real e: dot.easeInOut(dot.splitT)
            readonly property real across: (half.index ? 1 : -1) * dot.spread * dot.hopLift
            readonly property real extent: dot.size * 0.7
            x: dot.splitFromX + (dot.cx - dot.splitFromX) * half.e + (dot.vertical ? half.across : 0) - half.extent / 2
            y: dot.splitFromY + (dot.cy - dot.splitFromY) * half.e + (dot.vertical ? 0 : half.across) - half.extent / 2
            width: half.extent
            height: half.extent
            radius: half.extent / 2
            color: dot.color
            visible: dot.splitting && splitAnim.running
            antialiasing: true
        }
    }
    ParallelAnimation {
        id: splitAnim
        NumberAnimation { target: dot; property: "splitT"; from: 0; to: 1; duration: dot.unit * 1.6 }
        SequentialAnimation {
            NumberAnimation { target: dot; property: "spread"; to: 1; duration: dot.unit * 0.7; easing.type: Easing.OutQuad }
            NumberAnimation { target: dot; property: "spread"; to: 0; duration: dot.unit * 0.9; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: dot.splitGhost }
            NumberAnimation { target: ghost; property: "scale"; to: 0; duration: dot.unit * 0.35; easing.type: Easing.InQuad }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "scale"; value: 0 }
            PauseAnimation { duration: dot.unit * 1.4 }
            NumberAnimation { target: pill; property: "scale"; to: 1; duration: dot.unit * 0.5; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }
    }

    // "flash": no motion at all; the dot shows up on the new cell and blinks twice.
    SequentialAnimation {
        id: flashAnim
        PropertyAction { target: pill; property: "opacity"; value: 1 }
        PauseAnimation { duration: dot.unit * 0.3 }
        PropertyAction { target: pill; property: "opacity"; value: 0 }
        PauseAnimation { duration: dot.unit * 0.25 }
        PropertyAction { target: pill; property: "opacity"; value: 1 }
        PauseAnimation { duration: dot.unit * 0.3 }
        PropertyAction { target: pill; property: "opacity"; value: 0 }
        PauseAnimation { duration: dot.unit * 0.25 }
        PropertyAction { target: pill; property: "opacity"; value: 1 }
    }

    // "wrap": the dot leaves the row past the end away from the new cell, and comes back
    // in from the other end to reach it the long way round. `wrapExitAt` is the
    // position past the end it heads for; `wrapExit` and `wrapEntry` are that and the
    // re-entry point as offsets from the new cell.
    property real wrapExitAt: 0
    property real wrapExit: 0
    property real wrapEntry: 0
    property int wrapPhase: 0   // 1 while leaving, 2 while coming back in
    SequentialAnimation {
        id: wrapAnim
        PropertyAction { target: dot; property: "wrapPhase"; value: 1 }
        NumberAnimation { target: dot; property: "shift"; to: dot.wrapExit; duration: dot.unit * 0.9; easing.type: Easing.InQuad }
        PropertyAction { target: dot; property: "shift"; value: dot.wrapEntry }
        PropertyAction { target: dot; property: "wrapPhase"; value: 2 }
        NumberAnimation { target: dot; property: "shift"; to: 0; duration: dot.unit * 1.3; easing.type: Easing.OutQuad }
        PropertyAction { target: dot; property: "wrapPhase"; value: 0 }
    }
    NumberAnimation {
        id: wrapEnter
        target: dot; property: "shift"; to: 0
        duration: dot.unit * 1.3
        easing.type: Easing.OutQuad
    }

    // "steps": the dot jumps to the new cell in a few discrete stops, holding still
    // between them (see `stepShift`).
    NumberAnimation {
        id: stepsAnim
        target: dot; property: "stepT"; from: 0; to: 1
        duration: dot.unit * 0.6 * dot.stepCount
    }

    // "boomerang": the dot first draws back a whole cell away from the new one, then
    // flies across and lands.
    property real backTo: 0
    SequentialAnimation {
        id: boomerangAnim
        NumberAnimation { target: dot; property: "shift"; to: dot.backTo; duration: dot.unit * 0.8; easing.type: Easing.InOutSine }
        NumberAnimation { target: dot; property: "shift"; to: 0; duration: dot.unit * 1.2; easing.type: Easing.InOutCubic }
    }
}
