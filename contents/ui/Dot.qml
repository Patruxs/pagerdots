// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

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
    // Colour of the surface behind the dot. "roll" paints a spot of it on the dot
    // so that the turning shows.
    property color backgroundColor: "white"
    // Base duration in ms; every animation is a multiple of it. Pass Kirigami's
    // longDuration (scaled by the speed setting) so the widget follows the global
    // animation speed setting.
    property int unit: 200
    // Whether the cells run top to bottom rather than left to right, and which way
    // across the row "hop" jumps and "drop" falls in from (-1 for up/left, +1 for down/right).
    property bool vertical: false
    property real hopSign: -1

    // "pop", "fade", "shift", "drop", "flip", "bubble", "sparks", "pour", "ring", "blink"
    // and "wipe" swap the dot in place; everything else moves it across the panel.
    readonly property bool swaps: animation === "pop" || animation === "fade"
                                  || animation === "shift" || animation === "drop"
                                  || animation === "flip" || animation === "bubble"
                                  || animation === "sparks" || animation === "pour"
                                  || animation === "ring" || animation === "blink"
                                  || animation === "wipe"
    readonly property bool slides: !swaps && animation !== "none"
    // "fluid", "float" and "ribbon" are driven by a spring simulation (see `sim`) rather
    // than the Behaviors below; "fluid" stretches with a soft trail spring, "float" stays
    // round, and "ribbon" trails a streak from a softer trail spring still.
    readonly property bool fluid: animation === "fluid"
    readonly property bool floats: animation === "float"
    readonly property bool ribbon: animation === "ribbon"
    readonly property bool sprung: fluid || floats || ribbon
    // "elastic", "streak", "fluid", "ribbon" and "rail" keep the dot round and draw the
    // gap between the two trackers (see below) as a separate band, streak, neck or rail
    // rather than stretching the dot.
    readonly property bool tethered: animation === "elastic"
    readonly property bool streaks: animation === "streak" || ribbon
    readonly property bool rails: animation === "rail"
    readonly property bool round: tethered || streaks || fluid || rails
    // "zip" thins the pill the further it is stretched, so it streaks across as a fine line.
    readonly property bool zips: animation === "zip"
    // How long the dot takes to leave the old cell and settle on the new one, so that
    // whatever is underneath can time its own fade to it.
    readonly property int travel: sprung ? unit * 2.5
                                : slides ? Math.max(leadDelay + leadDuration, trailDelay + trailDuration)
                                : sparks ? unit * 2.4
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
    onCxChanged: retargetFluid()
    onCyChanged: retargetFluid()

    // Two trackers per axis follow the target centre, and the pill spans the gap between
    // them. With equal timing they coincide and the dot simply slides; in "stretch" the
    // lead tracker races ahead while the trail one lags, so the dot elongates into a
    // pill towards the new desktop and then contracts onto it. "elastic", "streak" and
    // "fluid" draw the gap as a band, a fading streak or a liquid neck instead.
    property real leadX: sprung ? sim.lx : cx
    property real leadY: sprung ? sim.ly : cy
    property real trailX: fluid || ribbon ? sim.tx : floats ? sim.lx : cx
    property real trailY: fluid || ribbon ? sim.ty : floats ? sim.ly : cy
    // Where the head of the dot is drawn: the lead tracker, pulled back along the row
    // by `wind` while "slingshot" winds up.
    readonly property real headX: leadX + (vertical ? 0 : wind)
    readonly property real headY: leadY + (vertical ? wind : 0)
    // Where the round dot itself sits: on the head, except in "rail", where the lead
    // tracker is the tip of the rail and the dot follows behind on the trail tracker.
    readonly property real dotX: rails ? trailX : headX
    readonly property real dotY: rails ? trailY : headY

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
        case "bridge":  return unit * 1.5;
        case "elastic": return unit * 1.5;
        case "rail":    return unit * 1;
        case "streak":  return unit * 1.75;
        case "zip":     return unit * 1.25;
        case "snap":    return unit * 1.75;
        case "lift":    return unit * 2.25;
        case "roll":    return unit * 2.5;
        case "loop":    return unit * 2.5;
        case "bounce":  return unit * 2.5;
        case "slingshot": return unit * 1.5;
        case "jelly":   return unit * 2.5;
        case "spring":  return unit * 2.75;
        default:        return unit * 2;
        }
    }
    readonly property int leadEasing: {
        switch (animation) {
        case "bounce": return Easing.OutBack;
        case "jelly":  return Easing.OutBack;
        case "slingshot": return Easing.OutBack;
        case "spring": return Easing.OutElastic;
        case "hop":    return Easing.InOutSine;
        case "lift":   return Easing.InOutCubic;
        case "roll":   return Easing.OutCubic;
        case "zip":    return Easing.OutExpo;   // off like a shot, then coasts in
        case "snap":   return Easing.InCubic;   // drawn in ever faster, stopped by the impact
        case "rail":   return Easing.OutExpo;   // the rail shoots out ahead of the dot
        case "swing":  return Easing.InOutSine; // with the dip below, a pendulum's arc
        default:       return Easing.BezierSpline;
        }
    }
    readonly property real leadOvershoot: animation === "bounce" ? 2.2 : animation === "slingshot" ? 1.6 : 1.1
    // "slingshot" holds the lead on the old cell while it is drawn back (see `wind`),
    // then lets it fly.
    readonly property int leadDelay: animation === "slingshot" ? unit * 0.7 : 0
    // "bridge" holds the trail on the old cell until the lead has all but arrived, so
    // the pill first spans both cells and then draws in behind itself. "slingshot"
    // holds it while the lead draws back, so the pill stretches like the band of a
    // slingshot, "zip" only until the lead is well away, and "rail" a moment, so the
    // rail is seen to be laid before the dot sets off along it.
    readonly property int trailDelay: {
        switch (animation) {
        case "bridge":    return unit * 0.9;
        case "slingshot": return unit * 0.9;
        case "zip":       return unit * 0.2;
        case "rail":      return unit * 0.15;
        default:          return 0;
        }
    }
    readonly property int trailDuration: {
        switch (animation) {
        case "stretch":   return unit * 2.25;
        case "bridge":    return unit * 1.5;
        case "elastic":   return unit * 2.5;
        case "streak":    return unit * 2.75;
        case "slingshot": return unit * 1.1;
        case "zip":       return unit * 1.3;
        case "rail":      return unit * 2;
        default:          return leadDuration;
        }
    }
    readonly property int trailEasing: {
        switch (animation) {
        case "stretch":   return Easing.InOutQuart;
        case "bridge":    return Easing.InOutCubic;
        case "elastic":   return Easing.InQuart;    // the band stays taut, then snaps in
        case "streak":    return Easing.InOutCubic;
        case "slingshot": return Easing.InOutCubic;
        case "zip":       return Easing.InOutExpo;
        case "snap":      return Easing.InQuart;    // lags the lead, smearing the dot as it speeds up
        case "rail":      return Easing.BezierSpline; // the dot slides along the rail as usual
        default:          return leadEasing;
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
    // The overshoot only applies to OutBack, the amplitude and period only to OutElastic,
    // and the curve only to BezierSpline.
    component LeadAnimation: SequentialAnimation {
        id: leadAnimation
        property bool cutIn: false
        property var curve: dot.smoothCurve
        // A move cutting in on another does not wind up again first.
        PauseAnimation { duration: leadAnimation.cutIn ? 0 : dot.leadDelay }
        NumberAnimation {
            duration: dot.leadDuration
            easing.type: dot.leadEasing
            easing.overshoot: dot.leadOvershoot
            easing.amplitude: 1
            easing.period: 0.45
            easing.bezierCurve: leadAnimation.curve
        }
    }
    component TrailAnimation: SequentialAnimation {
        id: trailAnimation
        property var curve: dot.smoothCurve
        PauseAnimation { duration: dot.trailDelay }
        NumberAnimation {
            duration: dot.trailDuration
            easing.type: dot.trailEasing
            easing.overshoot: dot.leadOvershoot
            easing.amplitude: 1
            easing.period: 0.45
            easing.bezierCurve: trailAnimation.curve
        }
    }
    Mover on leadX {
        id: leadMoverX
        current: dot.leadX
        span: dot.leadDuration
        enabled: dot.ready && dot.slides && !dot.sprung
        LeadAnimation { cutIn: leadMoverX.cutIn; curve: leadMoverX.curve }
    }
    Mover on leadY {
        id: leadMoverY
        current: dot.leadY
        span: dot.leadDuration
        enabled: dot.ready && dot.slides && !dot.sprung
        LeadAnimation { cutIn: leadMoverY.cutIn; curve: leadMoverY.curve }
    }
    Mover on trailX {
        id: trailMoverX
        current: dot.trailX
        span: dot.trailDuration
        enabled: dot.ready && dot.slides && !dot.sprung
        TrailAnimation { curve: trailMoverX.curve }
    }
    Mover on trailY {
        id: trailMoverY
        current: dot.trailY
        span: dot.trailDuration
        enabled: dot.ready && dot.slides && !dot.sprung
        TrailAnimation { curve: trailMoverY.curve }
    }

    // "fluid" and "float": the lead and trail trackers are two damped springs pulled
    // towards the target, integrated every frame. Unlike a timed animation, a spring
    // keeps its momentum when the target changes mid-flight, so rapid switching stays
    // smooth. In "fluid" the lead is a stiff spring and the trail a soft one, so the
    // dot stretches in proportion to how fast it is moving; "float" only uses the lead,
    // a softer and slightly underdamped spring, so the dot drifts over and eases to a
    // stop with the faintest of overshoots. The constants are scaled so that the settle
    // time follows `unit` like the other animations.
    FrameAnimation {
        id: sim
        running: false
        property real lx: 0
        property real ly: 0
        property real tx: 0
        property real ty: 0
        property real vlx: 0
        property real vly: 0
        property real vtx: 0
        property real vty: 0

        function snap() {
            stop();
            lx = tx = dot.cx;
            ly = ty = dot.cy;
            vlx = vly = vtx = vty = 0;
        }
        onTriggered: {
            const s = 200 / Math.max(1, dot.unit);
            // lead: stiff, just under critical damping ("fluid", "ribbon"), or softer
            // and a little less damped still ("float"); trail: softer, critically damped,
            // and softer again for "ribbon", so its streak draws out long behind the dot
            const kl = (dot.floats ? 110 : 170) * s * s, cl = (dot.floats ? 18 : 23.5) * s;
            const kt = (dot.ribbon ? 60 : 90) * s * s, ct = (dot.ribbon ? 15.5 : 19) * s;
            // Sub-step so that a stalled frame cannot blow the integration up.
            const dt = Math.min(frameTime, 0.05);
            const steps = Math.ceil(dt / 0.004), h = dt / steps;
            for (let i = 0; i < steps; i++) {
                vlx += (kl * (dot.cx - lx) - cl * vlx) * h;  lx += vlx * h;
                vly += (kl * (dot.cy - ly) - cl * vly) * h;  ly += vly * h;
                vtx += (kt * (dot.cx - tx) - ct * vtx) * h;  tx += vtx * h;
                vty += (kt * (dot.cy - ty) - ct * vty) * h;  ty += vty * h;
            }
            const still = Math.abs(dot.cx - lx) + Math.abs(dot.cy - ly)
                        + Math.abs(dot.cx - tx) + Math.abs(dot.cy - ty) < 0.1
                       && Math.abs(vlx) + Math.abs(vly) + Math.abs(vtx) + Math.abs(vty) < 1;
            if (still) snap();
        }
    }
    function retargetFluid() {
        if (!sprung) return;
        if (ready) sim.start();
        else sim.snap();
    }

    // Extra flourishes layered on top of the slide, driven by the animations below.
    property real hop: 0        // offset across the row while hopping or dropping in
    property real wind: 0       // offset of the head along the row while "slingshot" draws back
    property real windSign: -1  // which way along the row it draws back
    property real hopLift: 0    // how high the current hop goes, or how far the drop falls
    property real squish: 1     // scale along the row; the dot thins across it to compensate
    property real lift: 1       // uniform scale while "lift" carries the dot over
    property real flip: 1       // scale along the row while "flip" turns the dot over
    property real wink: 1       // scale across the row while "blink" closes and opens the dot
    property real along: 0      // offset along the row while "shift" slides the new dot in

    // "tumble": the dot turns over like a coin as it crosses. `tumbleT` is the phase of
    // that turn (one full turn per move), and the face is periodic in it, so a move that
    // cuts in on another carries on turning from where it was. The back face is drawn a
    // little lighter, so the turning shows even when the dot is not edge-on.
    readonly property bool tumbles: animation === "tumble"
    property real tumbleT: 0
    readonly property real tumbleFace: Math.cos(2 * Math.PI * tumbleT)
    readonly property real tumbleScale: tumbles ? Math.max(0.12, Math.abs(tumbleFace)) : 1
    readonly property real tumbleShade: tumbles ? 0.45 * Math.max(0, -tumbleFace) : 0

    // "loop": the dot loops the loop once on its way over. `curl` is the phase of that
    // loop in turns, and the offsets are periodic in it, so a move that cuts in on
    // another carries on turning from wherever the loop had got to rather than
    // snapping back to the start of it.
    readonly property bool loops: animation === "loop"
    property real curl: 0
    property real curlSign: 1   // which way along the row the loop leans
    // Half the room a hop has, since the loop rises twice its radius, and drawn out
    // along the row, where there is more space than across it.
    readonly property real curlRadius: loops ? hopLift * 0.5 : 0
    readonly property real curlAlong: curlRadius * 1.6 * curlSign * Math.sin(2 * Math.PI * curl)
    readonly property real curlAcross: curlRadius * (1 - Math.cos(2 * Math.PI * curl))

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
        case "flip":
            placeGhost(old);
            flipAnim.restart();
            break;
        case "blink":
            placeGhost(old);
            blinkAnim.restart();
            break;
        case "wipe":
            fromX = old.x + old.width / 2;
            fromY = old.y + old.height / 2;
            wipeDir = vertical ? (target.y < old.y ? -1 : 1) : (target.x < old.x ? -1 : 1);
            wipeAnim.restart();
            break;
        case "bloom":
            bloomAnim.restart();
            break;
        case "skip":
            skipAnim.restart();
            break;
        case "bubble":
            placeGhost(old);
            bubbleAnim.restart();
            break;
        case "dive":
            diveAnim.restart();
            break;
        case "swing":
            swingAnim.restart();
            break;
        case "arc":
            arcAnim.restart();
            break;
        case "beacon":
            beaconAnim.restart();
            break;
        case "tumble":
            // On to the next whole turn, so the dot lands face up; a move cutting in
            // mid-turn carries on from where it was, and turns at least half a turn more.
            tumbleAnim.from = tumbleT;
            tumbleAnim.to = Math.ceil(tumbleT + 0.5);
            tumbleAnim.restart();
            break;
        case "shift":
            placeGhost(old);
            shiftDist = size * 1.6 * (vertical ? (target.y < old.y ? -1 : 1) : (target.x < old.x ? -1 : 1));
            shiftAnim.restart();
            break;
        case "pour":
            placeGhost(old);
            fromX = old.x + old.width / 2;
            fromY = old.y + old.height / 2;
            pourAnim.restart();
            break;
        case "wave":
            waveAnim.restart();
            break;
        case "orbit":
            orbitAnim.restart();
            break;
        case "loop":
            // Only when the loop is not already turning, so that a move cutting in on
            // it does not mirror the offsets and jerk the dot across the row.
            if (!loopAnim.running) {
                curlSign = vertical ? (target.y < old.y ? -1 : 1) : (target.x < old.x ? -1 : 1);
            }
            loopAnim.from = curl;
            loopAnim.to = curl + 1;
            loopAnim.restart();
            break;
        case "pulse":
            pulseAnim.restart();
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
        case "footprints":
        case "wake":
        case "runway": {
            // One print on the old cell and one on every cell between it and the new
            // one, a cell's width apart, since all the cells are the same size. The
            // runway lights run from the cell after the old one up to the new one instead.
            const along = vertical ? target.y - old.y : target.x - old.x;
            const span = vertical ? target.height : target.width;
            printCount = 0;
            printStep = span * (along < 0 ? -1 : 1);
            printFrom = (vertical ? old.y + old.height / 2 : old.x + old.width / 2)
                        + (runway ? printStep : 0);
            printCount = Math.min(prints.count, Math.max(1, Math.round(Math.abs(along) / Math.max(1, span))));
            if (animation === "wake") ripple.restart();
            if (runway) runwayRev++;
            break;
        }
        case "ripple":
            ripple.restart();
            break;
        case "hop":
            hopAnim.restart();
            break;
        case "jelly":
            jellyAnim.restart();
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
        case "snap":
            snapAnim.restart();
            break;
        case "slingshot":
            // Draw back away from the new cell, whichever way along the row it lies.
            windSign = vertical ? (target.y < old.y ? 1 : -1) : (target.x < old.x ? 1 : -1);
            slingAnim.restart();
            break;
        case "sparks":
            placeGhost(old);
            sparksFromX = old.x + old.width / 2;
            sparksFromY = old.y + old.height / 2;
            sparksToX = target.x + target.width / 2;
            sparksToY = target.y + target.height / 2;
            sparksAnim.restart();
            break;
        }
    }
    function placeGhost(cell) {
        ghost.baseX = cell.x + (cell.width - size) / 2;
        ghost.baseY = cell.y + (cell.height - size) / 2;
        ghost.fall = 0;
        ghost.slide = 0;
        ghost.flip = 1;
        ghost.wink = 1;
    }
    // A mode change mid-animation must not leave the dot half faded, squashed or lifted.
    onAnimationChanged: {
        swap.stop();
        dropAnim.stop();
        flipAnim.stop();
        ripple.stop();
        hopAnim.stop();
        jellyAnim.stop();
        liftAnim.stop();
        elasticAnim.stop();
        glowAnim.stop();
        snapAnim.stop();
        slingAnim.stop();
        sparksAnim.stop();
        bubbleAnim.stop();
        diveAnim.stop();
        swingAnim.stop();
        pulseAnim.stop();
        waveAnim.stop();
        orbitAnim.stop();
        loopAnim.stop();
        ringAnim.stop();
        arcAnim.stop();
        beaconAnim.stop();
        tumbleAnim.stop();
        shiftAnim.stop();
        pourAnim.stop();
        blinkAnim.stop();
        wipeAnim.stop();
        bloomAnim.stop();
        skipAnim.stop();
        sim.snap();
        ghost.visible = false;
        irisOut.visible = false;
        irisIn.visible = false;
        wipeOut.visible = false;
        wipeIn.visible = false;
        ring.opacity = 0;
        halo.opacity = 0;
        beacon.opacity = 0;
        beaconRing.opacity = 0;
        pill.opacity = 1;
        pill.scale = 1;
        hop = 0;
        squish = 1;
        lift = 1;
        flip = 1;
        wink = 1;
        wind = 0;
        along = 0;
        curl = 0;
        tumbleT = 0;
        pourT = 0;
        orbitT = 0;
        swarmT = 0;
        printCount = 0;
    }

    // "footprints" and "wake": a mark is left on each cell as the dot passes over it and
    // fades away behind it, a faint print for "footprints" and a ring spreading outwards
    // for "wake". The marks are laid out from the old cell towards the new one when the
    // move starts, and each shows itself once the dot has gone by.
    // "runway": the same marks, but as small lights that come on one after another ahead
    // of the dot, from the cell after the old one up to the new one, and go out as the
    // dot reaches each of them. `runwayRev` is bumped to light them up.
    readonly property bool wakes: animation === "wake"
    readonly property bool runway: animation === "runway"
    property real printFrom: 0
    property real printStep: 0
    property int printCount: 0
    property int runwayRev: 0
    Repeater {
        id: prints
        model: 8
        Rectangle {
            id: mark
            required property int index
            property real grow: 1
            readonly property real extent: dot.size * (dot.wakes ? 0.9 : dot.runway ? 0.55 : 0.85) * grow
            readonly property real at: dot.printFrom + dot.printStep * index
            readonly property real head: dot.vertical ? dot.headY : dot.headX
            // Gone by: the dot has moved on from this cell in the direction of travel.
            readonly property bool passed: index < dot.printCount
                                           && (dot.printStep > 0 ? head > at + dot.size * 0.6
                                                                 : head < at - dot.size * 0.6)
            // Reached: the dot is about to cover this cell, so its runway light goes out.
            readonly property bool reached: index < dot.printCount
                                            && (dot.printStep > 0 ? head > at - dot.size * 0.5
                                                                  : head < at + dot.size * 0.5)
            x: (dot.vertical ? dot.cx : at) - extent / 2
            y: (dot.vertical ? at : dot.cy) - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: dot.wakes ? "transparent" : dot.color
            border.color: dot.color
            border.width: dot.wakes ? Math.max(1, dot.size / 5) : 0
            opacity: 0
            visible: (dot.animation === "footprints" || dot.wakes || dot.runway) && opacity > 0
            antialiasing: true
            onPassedChanged: if (passed && !dot.runway) printFade.restart()
            onReachedChanged: if (reached && dot.runway && opacity > 0) lightOff.restart()
            SequentialAnimation {
                id: printFade
                PropertyAction { target: mark; property: "opacity"; value: dot.wakes ? 0.7 : 0.5 }
                PropertyAction { target: mark; property: "grow"; value: 1 }
                ParallelAnimation {
                    NumberAnimation { target: mark; property: "opacity"; to: 0; duration: dot.unit * (dot.wakes ? 2.5 : 3); easing.type: Easing.InQuad }
                    NumberAnimation { target: mark; property: "grow"; to: dot.wakes ? 3 : 1; duration: dot.unit * 2.5; easing.type: Easing.OutCubic }
                }
            }
            // The runway lights come on in turn, a little after the one before, and each
            // goes out as the dot reaches it. A new move relights the ones it needs and
            // puts out the rest, so a cut-in does not leave stray lights along the row.
            Connections {
                target: dot
                function onRunwayRevChanged() {
                    lightOff.stop();
                    if (mark.index < dot.printCount && !mark.reached) {
                        lightOn.restart();
                    } else {
                        lightOn.stop();
                        mark.opacity = 0;
                    }
                }
            }
            SequentialAnimation {
                id: lightOn
                PauseAnimation { duration: dot.unit * 0.1 * mark.index }
                PropertyAction { target: mark; property: "grow"; value: 0.4 }
                ParallelAnimation {
                    NumberAnimation { target: mark; property: "opacity"; to: 0.55; duration: dot.unit * 0.35; easing.type: Easing.OutQuad }
                    NumberAnimation { target: mark; property: "grow"; to: 1; duration: dot.unit * 0.5; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                }
            }
            NumberAnimation {
                id: lightOff
                target: mark
                property: "opacity"
                to: 0
                duration: dot.unit * 0.7
                easing.type: Easing.OutQuad
            }
        }
    }

    // "glow": a soft halo that blooms around the dot as it sets off and fades once it lands.
    Rectangle {
        id: halo
        objectName: "halo"
        readonly property real extent: dot.size * 2.6
        x: dot.headX - extent / 2
        y: dot.headY - extent / 2
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

    // "comet" and "blur": copies that follow the dot with a growing delay, spreading out
    // behind it while it moves and tucking back under it at rest. "comet" uses three
    // that shrink and fade into a tail; "blur" four full-size, faint ones that lag only
    // a little, so the dot smears like a motion blur and is sharp again when it stops.
    readonly property bool comet: animation === "comet"
    readonly property bool blurs: animation === "blur"
    Repeater {
        model: 4
        Rectangle {
            id: follower
            required property int index
            readonly property real k: index + 1
            readonly property real extent: dot.comet ? dot.size * (1 - 0.2 * k) : dot.size
            readonly property real lag: dot.comet ? 0.22 : 0.09
            property real fx: dot.cx
            property real fy: dot.cy

            x: fx - extent / 2
            y: fy - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: dot.color
            opacity: dot.comet ? 0.55 - 0.15 * k : 0.45 - 0.1 * k
            visible: dot.blurs || (dot.comet && index < 3)
            antialiasing: true

            Mover on fx {
                id: followerMoverX
                current: follower.fx
                span: dot.leadDuration * (1 + follower.lag * follower.k)
                enabled: dot.ready && (dot.comet || dot.blurs)
                NumberAnimation { duration: followerMoverX.span; easing.type: Easing.BezierSpline; easing.bezierCurve: followerMoverX.curve }
            }
            Mover on fy {
                id: followerMoverY
                current: follower.fy
                span: dot.leadDuration * (1 + follower.lag * follower.k)
                enabled: dot.ready && (dot.comet || dot.blurs)
                NumberAnimation { duration: followerMoverY.span; easing.type: Easing.BezierSpline; easing.bezierCurve: followerMoverY.curve }
            }
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

    // Geometry shared by the pill and the spans: the distance between the trackers
    // along the row, and where that stretch starts.
    readonly property real gap: vertical ? Math.abs(headY - trailY) : Math.abs(headX - trailX)
    readonly property real gapStart: vertical ? Math.min(headY, trailY) : Math.min(headX, trailX)
    // Thickness of the pill across the row: the dot's size, except that "zip" thins it
    // the further it is stretched, so it streaks across as a fine line.
    readonly property real thickness: zips ? size * (1 - 0.55 * Math.min(1, gap / (size * 4))) : size

    // The span between the trail and lead trackers, along the row. "elastic" draws it
    // as a thin band tethering the dot to the old cell, "streak" as a streak that
    // fades away from the dot, "fluid" as the neck of a stretching drop. All vanish
    // once the trackers meet.
    component Span: Rectangle {
        required property real thickness
        readonly property bool forward: dot.vertical ? dot.headY >= dot.trailY : dot.headX >= dot.trailX
        x: dot.vertical ? dot.headX - thickness / 2 : dot.gapStart
        y: dot.vertical ? dot.gapStart : dot.headY - thickness / 2
        width: dot.vertical ? thickness : dot.gap
        height: dot.vertical ? dot.gap : thickness
        radius: thickness / 2
        antialiasing: true
    }
    Span {
        id: band
        objectName: "band"
        visible: dot.tethered && dot.target !== null
        thickness: Math.max(1.5, dot.size * 0.35)
        color: dot.color
        opacity: 0.9
    }
    Span {
        id: streak
        objectName: "streak"
        visible: dot.streaks && dot.target !== null
        thickness: dot.size * (dot.ribbon ? 0.45 : 0.6)
        opacity: dot.ribbon ? 0.7 : 0.85
        gradient: Gradient {
            orientation: dot.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: streak.forward ? Qt.alpha(dot.color, 0) : dot.color }
            GradientStop { position: 1; color: streak.forward ? dot.color : Qt.alpha(dot.color, 0) }
        }
    }
    // "rail": a thin line laid from the dot to the new cell, which the dot then slides
    // along, taking it in as it goes.
    Span {
        id: rail
        objectName: "rail"
        visible: dot.rails && dot.target !== null
        thickness: Math.max(1.5, dot.size * 0.3)
        color: dot.color
        opacity: 0.8
    }

    // "fluid": the further the drop is stretched, the thinner its neck and the smaller
    // the tail it leaves on the old cell, as if its volume flowed into the head.
    readonly property real stretched: Math.min(1, gap / (size * 3))
    Span {
        id: neck
        objectName: "neck"
        visible: dot.fluid && dot.target !== null
        thickness: Math.max(1.5, dot.size * (1 - 0.7 * dot.stretched))
        color: dot.color
    }
    Rectangle {
        id: tail
        objectName: "tail"
        readonly property real extent: dot.size * (1 - 0.55 * dot.stretched)
        x: dot.trailX - extent / 2
        y: dot.trailY - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: dot.color
        visible: dot.fluid && dot.target !== null
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

    // "beacon": a faint marker lights up on the new cell as soon as the move starts and a
    // ring pulses out from it, calling the dot over; the dot glides across and takes its
    // place, and the marker fades under it as it lands.
    readonly property bool beacons: animation === "beacon"
    Rectangle {
        id: beacon
        objectName: "beacon"
        x: dot.cx - dot.size / 2
        y: dot.cy - dot.size / 2
        width: dot.size
        height: dot.size
        radius: dot.size / 2
        color: dot.color
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    Rectangle {
        id: beaconRing
        objectName: "beaconRing"
        property real extent: dot.size
        x: dot.cx - extent / 2
        y: dot.cy - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: "transparent"
        border.color: dot.color
        border.width: Math.max(1, dot.size / 5)
        opacity: 0
        visible: opacity > 0
        antialiasing: true
    }
    ParallelAnimation {
        id: beaconAnim
        SequentialAnimation {
            ParallelAnimation {
                NumberAnimation { target: beacon; property: "opacity"; from: 0; to: 0.45; duration: dot.unit * 0.4; easing.type: Easing.OutQuad }
                NumberAnimation { target: beacon; property: "scale"; from: 0.3; to: 1; duration: dot.unit * 0.6; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            }
            PauseAnimation { duration: Math.max(0, dot.leadDuration - dot.unit * 1.1) }
            NumberAnimation { target: beacon; property: "opacity"; to: 0; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: beaconRing; property: "extent"; from: dot.size * 0.8; to: dot.size * 3.2; duration: dot.unit * 1.8; easing.type: Easing.OutCubic }
            NumberAnimation { target: beaconRing; property: "opacity"; from: 0.6; to: 0; duration: dot.unit * 1.8; easing.type: Easing.InQuad }
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

    // "wipe": a curtain sweeps along the row in the direction of travel, wiping the dot off
    // the old cell behind it and painting it onto the new cell as it goes. Each half is a
    // copy of the dot inside a clipping window: `reveal` is how much of the dot shows,
    // and the window is anchored at the dot's leading edge for the one being wiped off
    // and at its trailing edge for the one being painted on.
    readonly property bool wipes: animation === "wipe"
    property real wipeDir: 1
    component Wiper: Item {
        id: wiper
        property real atX: 0
        property real atY: 0
        property real reveal: 1
        property bool leading: false
        readonly property real shown: dot.size * Math.max(0, Math.min(1, reveal))
        // Whether the window hangs off the far (right/bottom) edge of the dot.
        readonly property bool far: (leading ? 1 : -1) * dot.wipeDir > 0
        readonly property real along: (dot.vertical ? atY : atX) - dot.size / 2 + (far ? dot.size - shown : 0)
        x: dot.vertical ? atX - dot.size / 2 : along
        y: dot.vertical ? along : atY - dot.size / 2
        width: dot.vertical ? dot.size : shown
        height: dot.vertical ? shown : dot.size
        clip: true
        visible: false
        Rectangle {
            x: (wiper.atX - dot.size / 2) - wiper.x
            y: (wiper.atY - dot.size / 2) - wiper.y
            width: dot.size
            height: dot.size
            radius: dot.size / 2
            color: dot.color
            antialiasing: true
        }
    }
    Wiper {
        id: wipeOut
        objectName: "wipeOut"
        atX: dot.fromX
        atY: dot.fromY
        leading: true
    }
    Wiper {
        id: wipeIn
        objectName: "wipeIn"
        atX: dot.cx
        atY: dot.cy
        leading: false
    }
    ParallelAnimation {
        id: wipeAnim
        SequentialAnimation {
            PropertyAction { target: wipeOut; property: "reveal"; value: 1 }
            PropertyAction { target: wipeOut; property: "visible"; value: true }
            NumberAnimation { target: wipeOut; property: "reveal"; to: 0; duration: dot.unit * 1.1; easing.type: Easing.InOutSine }
            PropertyAction { target: wipeOut; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "opacity"; value: 0 }
            PropertyAction { target: wipeIn; property: "reveal"; value: 0 }
            PropertyAction { target: wipeIn; property: "visible"; value: true }
            PauseAnimation { duration: dot.unit * 0.35 }
            NumberAnimation { target: wipeIn; property: "reveal"; to: 1; duration: dot.unit * 1.1; easing.type: Easing.InOutSine }
            PropertyAction { target: pill; property: "opacity"; value: 1 }
            PropertyAction { target: wipeIn; property: "visible"; value: false }
        }
    }

    // Copy of the dot left on the old cell during a swap, animating out. `fall` moves
    // it across the row, away from where "hop" jumps to (for "drop"); `slide` moves it
    // along the row (for "shift"); `flip` turns it edge-on (for "flip"); `wink` closes it
    // to a line across the row (for "blink").
    Rectangle {
        id: ghost
        objectName: "ghost"
        property real baseX: 0
        property real baseY: 0
        property real fall: 0
        property real slide: 0
        property real flip: 1
        property real wink: 1
        x: baseX + (dot.vertical ? -fall * dot.hopSign : slide)
        y: baseY + (dot.vertical ? slide : -fall * dot.hopSign)
        width: dot.size
        height: dot.size
        radius: dot.size / 2
        color: dot.color
        visible: false
        transformOrigin: Item.Center
        antialiasing: true
        transform: Scale {
            origin.x: ghost.width / 2
            origin.y: ghost.height / 2
            xScale: dot.vertical ? ghost.wink : ghost.flip
            yScale: dot.vertical ? ghost.flip : ghost.wink
        }
    }

    // The dot itself. A capsule while stretched, a circle otherwise.
    Rectangle {
        id: pill
        objectName: "pill"
        readonly property real length: dot.round ? 0 : dot.gap
        readonly property real start: dot.round ? (dot.vertical ? dot.dotY : dot.dotX) : dot.gapStart
        x: (dot.vertical ? dot.dotX : start) - dot.thickness / 2
           + (dot.vertical ? (dot.hop + dot.curlAcross) * dot.hopSign : dot.curlAlong + dot.along)
        y: (dot.vertical ? start : dot.dotY) - dot.thickness / 2
           + (dot.vertical ? dot.curlAlong + dot.along : (dot.hop + dot.curlAcross) * dot.hopSign)
        width: (dot.vertical ? 0 : length) + dot.thickness
        height: (dot.vertical ? length : 0) + dot.thickness
        radius: dot.thickness / 2
        color: Qt.alpha(dot.color, 1 - dot.tumbleShade)
        visible: dot.target !== null
        transformOrigin: Item.Center
        antialiasing: true
        // `turn` is the scale along the row from the dot being turned over, by "flip" or "tumble".
        readonly property real turn: dot.flip * dot.tumbleScale
        transform: Scale {
            origin.x: pill.width / 2
            origin.y: pill.height / 2
            xScale: (dot.vertical ? dot.wink / dot.squish : dot.squish * pill.turn) * dot.lift
            yScale: (dot.vertical ? dot.squish * pill.turn : dot.wink / dot.squish) * dot.lift
        }

        // "roll": a spot of the background off the dot's centre, turned in proportion
        // to the distance travelled, so the dot looks like a ball rolling along the row.
        Item {
            objectName: "spot"
            anchors.centerIn: parent
            width: dot.size
            height: dot.size
            visible: dot.animation === "roll"
            rotation: (dot.vertical ? dot.headY : dot.headX) / (Math.PI * dot.size) * 360
            Rectangle {
                readonly property real extent: dot.size * 0.42
                x: dot.size * 0.66 - extent / 2
                y: (dot.size - extent) / 2
                width: extent
                height: extent
                radius: extent / 2
                color: dot.backgroundColor
                opacity: 0.75
                antialiasing: true
            }
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

    // "skip": three arcs in a row while sliding, each lower and shorter than the last,
    // like a stone skipping across water, and a faint squash as it comes to rest.
    SequentialAnimation {
        id: skipAnim
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift; duration: dot.leadDuration * 0.2; easing.type: Easing.OutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration * 0.2; easing.type: Easing.InSine }
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.5; duration: dot.leadDuration * 0.16; easing.type: Easing.OutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration * 0.16; easing.type: Easing.InSine }
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.22; duration: dot.leadDuration * 0.13; easing.type: Easing.OutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration * 0.13; easing.type: Easing.InSine }
        NumberAnimation { target: dot; property: "squish"; to: 1.15; duration: dot.unit * 0.25; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 0.8; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
    }

    // "bloom": the dot swells into a large, faint disc as it sets off, drifts across as
    // that soft disc, and condenses back into a dot on the new cell. The first step
    // eases a bloom cut short by a new move on from where it was rather than restarting.
    ParallelAnimation {
        id: bloomAnim
        SequentialAnimation {
            NumberAnimation { target: dot; property: "lift"; to: 2.4; duration: dot.leadDuration * 0.45; easing.type: Easing.OutSine }
            NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.leadDuration * 0.55; easing.type: Easing.InOutCubic }
        }
        SequentialAnimation {
            NumberAnimation { target: pill; property: "opacity"; to: 0.3; duration: dot.leadDuration * 0.45; easing.type: Easing.OutSine }
            NumberAnimation { target: pill; property: "opacity"; to: 1; duration: dot.leadDuration * 0.55; easing.type: Easing.InOutCubic }
        }
    }

    // "swing": dip below the row and rise again while sliding, so that with the sine
    // easing of the slide the dot swings over on a pendulum's arc.
    SequentialAnimation {
        id: swingAnim
        NumberAnimation { target: dot; property: "hop"; to: -dot.hopLift; duration: dot.leadDuration / 2; easing.type: Easing.OutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration / 2; easing.type: Easing.InSine }
    }

    // "arc": a gentler cousin of "hop". The dot rises over the row in a shallow arc,
    // growing a little at the top as if coming towards the eye, and settles without a bump.
    ParallelAnimation {
        id: arcAnim
        SequentialAnimation {
            NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.75; duration: dot.leadDuration / 2; easing.type: Easing.OutSine }
            NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration / 2; easing.type: Easing.InSine }
        }
        SequentialAnimation {
            NumberAnimation { target: dot; property: "lift"; to: 1.3; duration: dot.leadDuration / 2; easing.type: Easing.OutSine }
            NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.leadDuration / 2; easing.type: Easing.InSine }
        }
    }

    // "wave": the dot undulates across the row as it crosses, as if carried on a wave,
    // and levels out as it settles.
    SequentialAnimation {
        id: waveAnim
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.8; duration: dot.leadDuration * 0.3; easing.type: Easing.InOutSine }
        NumberAnimation { target: dot; property: "hop"; to: -dot.hopLift * 0.55; duration: dot.leadDuration * 0.3; easing.type: Easing.InOutSine }
        NumberAnimation { target: dot; property: "hop"; to: dot.hopLift * 0.25; duration: dot.leadDuration * 0.25; easing.type: Easing.InOutSine }
        NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.leadDuration * 0.25; easing.type: Easing.InOutSine }
    }

    // "loop": the loop is turned by advancing `curl` a whole turn (see the offsets above).
    // It rests at 0 so that a mode change leaves the dot on its cell.
    NumberAnimation {
        id: loopAnim
        target: dot
        property: "curl"
        duration: dot.leadDuration * 0.9
        easing.type: Easing.InOutSine
        onFinished: dot.curl = 0
    }

    // "tumble": one full turn of the coin per move (see `tumbleT` above), timed to the
    // slide so that it turns fastest mid-way and settles face up as it lands. It rests at 0
    // so that a mode change leaves the dot face up.
    NumberAnimation {
        id: tumbleAnim
        target: dot
        property: "tumbleT"
        duration: dot.leadDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: dot.smoothCurve
        onFinished: dot.tumbleT = 0
    }

    // "orbit": a smaller dot peels off as the dot sets off, circles it twice on the way
    // over, and merges back into it as it lands. `orbitT` runs from 0 to 1 over the move,
    // and how far out the companion swings swells and falls away over that time, so it
    // leaves and rejoins the dot rather than appearing beside it.
    readonly property bool orbits: animation === "orbit"
    property real orbitT: 0
    Rectangle {
        id: moon
        objectName: "moon"
        readonly property real extent: dot.size * 0.5
        readonly property real angle: 2 * Math.PI * (dot.orbitT * 2 - 0.25)
        readonly property real reach: dot.hopLift * 0.9 * Math.sin(Math.PI * dot.orbitT)
        // Stretched along the row, where there is room, and kept within the cell across it.
        readonly property real along: Math.cos(angle) * reach * 1.5
        readonly property real across: Math.sin(angle) * reach
        x: dot.dotX + (dot.vertical ? across : along) - extent / 2
        y: dot.dotY + (dot.vertical ? along : across) - extent / 2
        width: extent
        height: extent
        radius: extent / 2
        color: dot.color
        opacity: Math.min(1, dot.orbitT * 6, (1 - dot.orbitT) * 6)
        visible: dot.orbits && orbitAnim.running
        antialiasing: true
    }
    NumberAnimation {
        id: orbitAnim
        target: dot
        property: "orbitT"
        from: 0
        to: 1
        duration: dot.leadDuration * 1.15
    }

    // "pulse": as the dot settles on the new cell it swells briefly, like a heartbeat.
    // The first step does nothing on a fresh move, but eases a swell that was cut short
    // by a new move back to round on the way, rather than carrying it over.
    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.leadDuration * 0.7; easing.type: Easing.OutCubic }
        NumberAnimation { target: dot; property: "lift"; to: 1.45; duration: dot.unit * 0.4; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.unit * 1.1; easing.type: Easing.OutCubic }
    }

    // "jelly": stretch out on departure, squash on arrival, then wobble back to round.
    SequentialAnimation {
        id: jellyAnim
        NumberAnimation { target: dot; property: "squish"; to: 1.45; duration: dot.unit * 0.6; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 0.8; duration: dot.unit * 0.7; easing.type: Easing.InOutSine }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 1.6; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.45 }
    }

    // "lift": the dot is picked up, grows as it is carried over, and is set down again.
    SequentialAnimation {
        id: liftAnim
        NumberAnimation { target: dot; property: "lift"; to: 1.5; duration: dot.leadDuration * 0.45; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "lift"; to: 0.92; duration: dot.leadDuration * 0.55; easing.type: Easing.InQuad }
        NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.unit * 0.8; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    // "dive": the opposite of "lift". The dot sinks away as it sets off, small and
    // faint as if passing beneath the row, and surfaces on the new cell.
    ParallelAnimation {
        id: diveAnim
        SequentialAnimation {
            NumberAnimation { target: dot; property: "lift"; to: 0.45; duration: dot.leadDuration * 0.4; easing.type: Easing.OutCubic }
            NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.leadDuration * 0.6; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        }
        SequentialAnimation {
            NumberAnimation { target: pill; property: "opacity"; to: 0.35; duration: dot.leadDuration * 0.4; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "opacity"; to: 1; duration: dot.leadDuration * 0.6; easing.type: Easing.OutQuad }
        }
    }

    // "elastic": once the band has snapped back into the dot, the dot wobbles from the impact.
    SequentialAnimation {
        id: elasticAnim
        PauseAnimation { duration: dot.trailDuration * 0.85 }
        NumberAnimation { target: dot; property: "squish"; to: 1.35; duration: dot.unit * 0.3; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 1.8; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
    }

    // "slingshot": the head is drawn back from the new cell, stretching the dot like the
    // band of a slingshot, and released as the lead flies (see `leadDelay`).
    SequentialAnimation {
        id: slingAnim
        NumberAnimation { target: dot; property: "wind"; to: dot.size * 1.2 * dot.windSign; duration: dot.unit * 0.7; easing.type: Easing.OutCubic }
        NumberAnimation { target: dot; property: "wind"; to: 0; duration: dot.unit * 0.4; easing.type: Easing.InQuad }
    }

    // "snap": drawn in ever faster, the dot hits the new cell at full speed, flattens
    // against it, and springs back to round.
    SequentialAnimation {
        id: snapAnim
        PauseAnimation { duration: dot.leadDuration }
        NumberAnimation { target: dot; property: "squish"; to: 0.7; duration: dot.unit * 0.2; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 1.5; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
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

    // "shift": the old dot slips a little way onwards and fades, while a new one fades in
    // just short of the new cell and slides the last stretch onto it, in the same
    // direction, so the eye reads one dot handing over to the next.
    property real shiftDist: 0
    ParallelAnimation {
        id: shiftAnim
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: ghost; property: "slide"; from: 0; to: dot.shiftDist; duration: dot.unit * 1.2; easing.type: Easing.OutCubic }
                NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: dot.unit * 0.9; easing.type: Easing.InOutSine }
            }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "opacity"; value: 0 }
            PropertyAction { target: dot; property: "along"; value: -dot.shiftDist }
            PauseAnimation { duration: dot.unit * 0.15 }
            ParallelAnimation {
                NumberAnimation { target: pill; property: "opacity"; to: 1; duration: dot.unit * 1.0; easing.type: Easing.OutQuad }
                NumberAnimation { target: dot; property: "along"; to: 0; duration: dot.unit * 1.6; easing.type: Easing.BezierSpline; easing.bezierCurve: dot.smoothCurve }
            }
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

    // "bubble": the ghost floats up off the old cell, swelling until it pops, while a
    // new dot rises from below onto the new cell and settles like a bubble surfacing.
    ParallelAnimation {
        id: bubbleAnim
        SequentialAnimation {
            PropertyAction { target: ghost; property: "opacity"; value: 1 }
            PropertyAction { target: ghost; property: "scale"; value: 1 }
            PropertyAction { target: ghost; property: "visible"; value: true }
            ParallelAnimation {
                NumberAnimation { target: ghost; property: "fall"; from: 0; to: -dot.hopLift * 0.9; duration: dot.unit * 0.9; easing.type: Easing.OutQuad }
                NumberAnimation { target: ghost; property: "scale"; from: 1; to: 1.3; duration: dot.unit * 0.9; easing.type: Easing.InQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: ghost; property: "scale"; to: 1.7; duration: dot.unit * 0.25; easing.type: Easing.OutQuad }
                NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: dot.unit * 0.25; easing.type: Easing.OutQuad }
            }
            PropertyAction { target: ghost; property: "visible"; value: false }
        }
        SequentialAnimation {
            PropertyAction { target: pill; property: "opacity"; value: 0 }
            PropertyAction { target: dot; property: "hop"; value: -dot.hopLift }
            PropertyAction { target: dot; property: "lift"; value: 0.5 }
            PauseAnimation { duration: dot.unit * 0.5 }
            ParallelAnimation {
                NumberAnimation { target: pill; property: "opacity"; to: 1; duration: dot.unit * 0.5; easing.type: Easing.OutQuad }
                NumberAnimation { target: dot; property: "hop"; to: 0; duration: dot.unit * 1.4; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                NumberAnimation { target: dot; property: "lift"; to: 1; duration: dot.unit * 1.4; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
            }
        }
    }

    // "flip": the ghost turns edge-on like a coin, and the dot turns back up on the new cell.
    SequentialAnimation {
        id: flipAnim
        PropertyAction { target: ghost; property: "opacity"; value: 1 }
        PropertyAction { target: ghost; property: "scale"; value: 1 }
        PropertyAction { target: ghost; property: "visible"; value: true }
        PropertyAction { target: dot; property: "flip"; value: 0 }
        NumberAnimation { target: ghost; property: "flip"; from: 1; to: 0; duration: dot.unit * 0.75; easing.type: Easing.InSine }
        PropertyAction { target: ghost; property: "visible"; value: false }
        NumberAnimation { target: dot; property: "flip"; from: 0; to: 1; duration: dot.unit * 0.75; easing.type: Easing.OutSine }
    }

    // "blink": the ghost closes to a thin line across the row, like an eye shutting, and
    // the dot opens out from a line on the new cell. The line is kept just visible at
    // its thinnest, so the eye can follow the dot from one cell to the other.
    SequentialAnimation {
        id: blinkAnim
        PropertyAction { target: ghost; property: "opacity"; value: 1 }
        PropertyAction { target: ghost; property: "scale"; value: 1 }
        PropertyAction { target: ghost; property: "visible"; value: true }
        PropertyAction { target: dot; property: "wink"; value: 0.2 }
        NumberAnimation { target: ghost; property: "wink"; from: 1; to: 0.2; duration: dot.unit * 0.6; easing.type: Easing.InSine }
        PropertyAction { target: ghost; property: "visible"; value: false }
        PauseAnimation { duration: dot.unit * 0.15 }
        NumberAnimation { target: dot; property: "wink"; from: 0.2; to: 1; duration: dot.unit * 0.9; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
    }
}
