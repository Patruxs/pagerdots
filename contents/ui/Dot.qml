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

    // "pop", "fade", "drop" and "flip" swap the dot in place; everything else moves it
    // across the panel.
    readonly property bool swaps: animation === "pop" || animation === "fade"
                                  || animation === "drop" || animation === "flip"
    readonly property bool slides: !swaps && animation !== "none"
    // "fluid" is driven by a spring simulation (see `sim`) rather than the Behaviors below.
    readonly property bool fluid: animation === "fluid"
    // "elastic", "streak" and "fluid" keep the dot round and draw the gap between the two
    // trackers (see below) as a separate band, streak or neck rather than stretching the dot.
    readonly property bool tethered: animation === "elastic"
    readonly property bool streaks: animation === "streak"
    readonly property bool round: tethered || streaks || fluid
    // How long the dot takes to leave the old cell and settle on the new one, so that
    // whatever is underneath can time its own fade to it.
    readonly property int travel: fluid ? unit * 2.5
                                : slides ? Math.max(leadDuration, trailDelay + trailDuration)
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
    property real leadX: fluid ? sim.lx : cx
    property real leadY: fluid ? sim.ly : cy
    property real trailX: fluid ? sim.tx : cx
    property real trailY: fluid ? sim.ty : cy

    // The default curve: a brief ease-in so the dot never jerks off the mark, then a
    // long, gentle deceleration onto the new cell (the "standard" curve of most
    // motion guidelines).
    readonly property var smoothCurve: [0.2, 0, 0, 1, 1, 1]

    readonly property int leadDuration: {
        switch (animation) {
        case "stretch": return unit * 1.5;
        case "bridge":  return unit * 1.5;
        case "elastic": return unit * 1.5;
        case "streak":  return unit * 1.75;
        case "lift":    return unit * 2.25;
        case "roll":    return unit * 2.5;
        case "bounce":  return unit * 2.5;
        case "jelly":   return unit * 2.5;
        case "spring":  return unit * 2.75;
        default:        return unit * 2;
        }
    }
    readonly property int leadEasing: {
        switch (animation) {
        case "bounce": return Easing.OutBack;
        case "jelly":  return Easing.OutBack;
        case "spring": return Easing.OutElastic;
        case "hop":    return Easing.InOutSine;
        case "lift":   return Easing.InOutCubic;
        case "roll":   return Easing.OutCubic;
        default:       return Easing.BezierSpline;
        }
    }
    readonly property real leadOvershoot: animation === "bounce" ? 2.2 : 1.1
    // "bridge" holds the trail on the old cell until the lead has all but arrived, so
    // the pill first spans both cells and then draws in behind itself.
    readonly property int trailDelay: animation === "bridge" ? unit * 0.9 : 0
    readonly property int trailDuration: {
        switch (animation) {
        case "stretch": return unit * 2.25;
        case "bridge":  return unit * 1.5;
        case "elastic": return unit * 2.5;
        case "streak":  return unit * 2.75;
        default:        return leadDuration;
        }
    }
    readonly property int trailEasing: {
        switch (animation) {
        case "stretch": return Easing.InOutQuart;
        case "bridge":  return Easing.InOutCubic;
        case "elastic": return Easing.InQuart;    // the band stays taut, then snaps in
        case "streak":  return Easing.InOutCubic;
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

    // The overshoot only applies to OutBack, the amplitude and period only to OutElastic,
    // and the curve only to BezierSpline.
    component LeadAnimation: NumberAnimation {
        duration: dot.leadDuration
        easing.type: dot.leadEasing
        easing.overshoot: dot.leadOvershoot
        easing.amplitude: 1
        easing.period: 0.45
        easing.bezierCurve: dot.smoothCurve
    }
    component TrailAnimation: SequentialAnimation {
        PauseAnimation { duration: dot.trailDelay }
        NumberAnimation {
            duration: dot.trailDuration
            easing.type: dot.trailEasing
            easing.overshoot: dot.leadOvershoot
            easing.amplitude: 1
            easing.period: 0.45
            easing.bezierCurve: dot.smoothCurve
        }
    }
    Behavior on leadX  { enabled: dot.ready && dot.slides && !dot.fluid; LeadAnimation {} }
    Behavior on leadY  { enabled: dot.ready && dot.slides && !dot.fluid; LeadAnimation {} }
    Behavior on trailX { enabled: dot.ready && dot.slides && !dot.fluid; TrailAnimation {} }
    Behavior on trailY { enabled: dot.ready && dot.slides && !dot.fluid; TrailAnimation {} }

    // "fluid": the lead and trail trackers are two damped springs pulled towards the
    // target, the lead a stiff one and the trail a soft one, integrated every frame.
    // The dot stretches in proportion to how fast it is moving and, unlike a timed
    // animation, keeps its momentum when the target changes mid-flight, so rapid
    // switching stays smooth. The constants are scaled so that the settle time
    // follows `unit` like the other animations.
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
            const kl = 170 * s * s, cl = 23.5 * s;   // lead: stiff, just under critical damping
            const kt = 90 * s * s, ct = 19 * s;      // trail: softer, critically damped
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
        if (!fluid) return;
        if (ready) sim.start();
        else sim.snap();
    }

    // Extra flourishes layered on top of the slide, driven by the animations below.
    property real hop: 0        // offset across the row while hopping or dropping in
    property real hopLift: 0    // how high the current hop goes, or how far the drop falls
    property real squish: 1     // scale along the row; the dot thins across it to compensate
    property real lift: 1       // uniform scale while "lift" carries the dot over
    property real flip: 1       // scale along the row while "flip" turns the dot over

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
        }
    }
    function placeGhost(cell) {
        ghost.baseX = cell.x + (cell.width - size) / 2;
        ghost.baseY = cell.y + (cell.height - size) / 2;
        ghost.fall = 0;
        ghost.flip = 1;
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
        sim.snap();
        ghost.visible = false;
        ring.opacity = 0;
        halo.opacity = 0;
        pill.opacity = 1;
        pill.scale = 1;
        hop = 0;
        squish = 1;
        lift = 1;
        flip = 1;
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

            Behavior on fx {
                enabled: dot.ready && (dot.comet || dot.blurs)
                NumberAnimation { duration: dot.leadDuration * (1 + follower.lag * follower.k); easing.type: Easing.BezierSpline; easing.bezierCurve: dot.smoothCurve }
            }
            Behavior on fy {
                enabled: dot.ready && (dot.comet || dot.blurs)
                NumberAnimation { duration: dot.leadDuration * (1 + follower.lag * follower.k); easing.type: Easing.BezierSpline; easing.bezierCurve: dot.smoothCurve }
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
    readonly property real gap: vertical ? Math.abs(leadY - trailY) : Math.abs(leadX - trailX)
    readonly property real gapStart: vertical ? Math.min(leadY, trailY) : Math.min(leadX, trailX)

    // The span between the trail and lead trackers, along the row. "elastic" draws it
    // as a thin band tethering the dot to the old cell, "streak" as a streak that
    // fades away from the dot, "fluid" as the neck of a stretching drop. All vanish
    // once the trackers meet.
    component Span: Rectangle {
        required property real thickness
        readonly property bool forward: dot.vertical ? dot.leadY >= dot.trailY : dot.leadX >= dot.trailX
        x: dot.vertical ? dot.leadX - thickness / 2 : dot.gapStart
        y: dot.vertical ? dot.gapStart : dot.leadY - thickness / 2
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
        thickness: dot.size * 0.6
        opacity: 0.85
        gradient: Gradient {
            orientation: dot.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop { position: 0; color: streak.forward ? Qt.alpha(dot.color, 0) : dot.color }
            GradientStop { position: 1; color: streak.forward ? dot.color : Qt.alpha(dot.color, 0) }
        }
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

    // Copy of the dot left on the old cell during a swap, animating out. `fall` moves
    // it across the row, away from where "hop" jumps to (for "drop"); `flip` turns it
    // edge-on (for "flip").
    Rectangle {
        id: ghost
        objectName: "ghost"
        property real baseX: 0
        property real baseY: 0
        property real fall: 0
        property real flip: 1
        x: baseX + (dot.vertical ? -fall * dot.hopSign : 0)
        y: baseY + (dot.vertical ? 0 : -fall * dot.hopSign)
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
            xScale: dot.vertical ? 1 : ghost.flip
            yScale: dot.vertical ? ghost.flip : 1
        }
    }

    // The dot itself. A capsule while stretched, a circle otherwise.
    Rectangle {
        id: pill
        objectName: "pill"
        readonly property real length: dot.round ? 0 : dot.gap
        readonly property real start: dot.round ? (dot.vertical ? dot.leadY : dot.leadX) : dot.gapStart
        x: (dot.vertical ? dot.leadX : start) - dot.size / 2 + (dot.vertical ? dot.hop * dot.hopSign : 0)
        y: (dot.vertical ? start : dot.leadY) - dot.size / 2 + (dot.vertical ? 0 : dot.hop * dot.hopSign)
        width: (dot.vertical ? 0 : length) + dot.size
        height: (dot.vertical ? length : 0) + dot.size
        radius: dot.size / 2
        color: dot.color
        visible: dot.target !== null
        transformOrigin: Item.Center
        antialiasing: true
        transform: Scale {
            origin.x: pill.width / 2
            origin.y: pill.height / 2
            xScale: (dot.vertical ? 1 / dot.squish : dot.squish * dot.flip) * dot.lift
            yScale: (dot.vertical ? dot.squish * dot.flip : 1 / dot.squish) * dot.lift
        }

        // "roll": a spot of the background off the dot's centre, turned in proportion
        // to the distance travelled, so the dot looks like a ball rolling along the row.
        Item {
            objectName: "spot"
            anchors.centerIn: parent
            width: dot.size
            height: dot.size
            visible: dot.animation === "roll"
            rotation: (dot.vertical ? dot.leadY : dot.leadX) / (Math.PI * dot.size) * 360
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

    // "elastic": once the band has snapped back into the dot, the dot wobbles from the impact.
    SequentialAnimation {
        id: elasticAnim
        PauseAnimation { duration: dot.trailDuration * 0.85 }
        NumberAnimation { target: dot; property: "squish"; to: 1.35; duration: dot.unit * 0.3; easing.type: Easing.OutQuad }
        NumberAnimation { target: dot; property: "squish"; to: 1; duration: dot.unit * 1.8; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.4 }
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
}
