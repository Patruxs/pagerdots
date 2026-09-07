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
    // across the row "hop" jumps (-1 for up/left, +1 for down/right).
    property bool vertical: false
    property real hopSign: -1

    // "pop" and "fade" swap the dot in place; everything else moves it across the panel.
    readonly property bool swaps: animation === "pop" || animation === "fade"
    readonly property bool slides: !swaps && animation !== "none"
    // "elastic" and "streak" keep the dot round and draw the gap between the two
    // trackers (see below) as a separate band or streak rather than stretching the dot.
    readonly property bool tethered: animation === "elastic"
    readonly property bool streaks: animation === "streak"
    readonly property bool round: tethered || streaks
    // How long the dot takes to leave the old cell and settle on the new one, so that
    // whatever is underneath can time its own fade to it.
    readonly property int travel: slides ? Math.max(leadDuration, trailDuration) : unit * 2

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
    // pill towards the new desktop and then contracts onto it. "elastic" and "streak"
    // draw the gap as a band or a fading streak instead.
    property real leadX: cx
    property real leadY: cy
    property real trailX: cx
    property real trailY: cy

    readonly property int leadDuration: {
        switch (animation) {
        case "stretch": return unit * 1.5;
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
        default:       return Easing.OutQuint;
        }
    }
    readonly property real leadOvershoot: animation === "bounce" ? 2.2 : 1.1
    readonly property int trailDuration: {
        switch (animation) {
        case "stretch": return unit * 2.25;
        case "elastic": return unit * 2.5;
        case "streak":  return unit * 2.75;
        default:        return leadDuration;
        }
    }
    readonly property int trailEasing: {
        switch (animation) {
        case "stretch": return Easing.InOutQuart;
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

    // The overshoot only applies to OutBack, the amplitude and period only to OutElastic.
    component LeadAnimation: NumberAnimation {
        duration: dot.leadDuration
        easing.type: dot.leadEasing
        easing.overshoot: dot.leadOvershoot
        easing.amplitude: 1
        easing.period: 0.45
    }
    component TrailAnimation: NumberAnimation {
        duration: dot.trailDuration
        easing.type: dot.trailEasing
        easing.overshoot: dot.leadOvershoot
        easing.amplitude: 1
        easing.period: 0.45
    }
    Behavior on leadX  { enabled: dot.ready && dot.slides; LeadAnimation {} }
    Behavior on leadY  { enabled: dot.ready && dot.slides; LeadAnimation {} }
    Behavior on trailX { enabled: dot.ready && dot.slides; TrailAnimation {} }
    Behavior on trailY { enabled: dot.ready && dot.slides; TrailAnimation {} }

    // Extra flourishes layered on top of the slide, driven by the animations below.
    property real hop: 0        // offset across the row while hopping
    property real hopLift: 0    // how high the current hop goes
    property real squish: 1     // scale along the row; the dot thins across it to compensate
    property real lift: 1       // uniform scale while "lift" carries the dot over

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
        switch (animation) {
        case "pop":
        case "fade":
            ghost.x = old.x + (old.width - size) / 2;
            ghost.y = old.y + (old.height - size) / 2;
            swap.restart();
            break;
        case "ripple":
            ripple.restart();
            break;
        case "hop": {
            // Jump as high as the cell allows without leaving it.
            const across = vertical ? target.width : target.height;
            hopLift = Math.max(size * 0.8, (across - size) / 2);
            hopAnim.restart();
            break;
        }
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
    // A mode change mid-animation must not leave the dot half faded, squashed or lifted.
    onAnimationChanged: {
        swap.stop();
        ripple.stop();
        hopAnim.stop();
        jellyAnim.stop();
        liftAnim.stop();
        elasticAnim.stop();
        glowAnim.stop();
        ghost.visible = false;
        ring.opacity = 0;
        halo.opacity = 0;
        pill.opacity = 1;
        pill.scale = 1;
        hop = 0;
        squish = 1;
        lift = 1;
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

    // "comet": smaller, fainter copies that follow the dot with a growing delay,
    // spreading out into a tail while it moves and tucking back under it at rest.
    Repeater {
        model: 3
        Rectangle {
            id: follower
            required property int index
            readonly property real k: index + 1
            readonly property real extent: dot.size * (1 - 0.2 * k)
            property real fx: dot.cx
            property real fy: dot.cy

            x: fx - extent / 2
            y: fy - extent / 2
            width: extent
            height: extent
            radius: extent / 2
            color: dot.color
            opacity: 0.55 - 0.15 * k
            visible: dot.animation === "comet"
            antialiasing: true

            Behavior on fx {
                enabled: dot.ready && dot.animation === "comet"
                NumberAnimation { duration: dot.leadDuration * (1 + 0.22 * follower.k); easing.type: Easing.OutQuint }
            }
            Behavior on fy {
                enabled: dot.ready && dot.animation === "comet"
                NumberAnimation { duration: dot.leadDuration * (1 + 0.22 * follower.k); easing.type: Easing.OutQuint }
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

    // The span between the trail and lead trackers, along the row. "elastic" draws it
    // as a thin band tethering the dot to the old cell, "streak" as a streak that
    // fades away from the dot. Both vanish once the trackers meet.
    component Span: Rectangle {
        required property real thickness
        readonly property bool forward: dot.vertical ? dot.leadY >= dot.trailY : dot.leadX >= dot.trailX
        x: dot.vertical ? dot.leadX - thickness / 2 : Math.min(dot.leadX, dot.trailX)
        y: dot.vertical ? Math.min(dot.leadY, dot.trailY) : dot.leadY - thickness / 2
        width: dot.vertical ? thickness : Math.abs(dot.leadX - dot.trailX)
        height: dot.vertical ? Math.abs(dot.leadY - dot.trailY) : thickness
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

    // Copy of the dot left on the old cell during "pop" and "fade", animating out.
    Rectangle {
        id: ghost
        objectName: "ghost"
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
        x: (dot.round ? dot.leadX : Math.min(dot.leadX, dot.trailX)) - dot.size / 2
           + (dot.vertical ? dot.hop * dot.hopSign : 0)
        y: (dot.round ? dot.leadY : Math.min(dot.leadY, dot.trailY)) - dot.size / 2
           + (dot.vertical ? 0 : dot.hop * dot.hopSign)
        width: (dot.round ? 0 : Math.abs(dot.leadX - dot.trailX)) + dot.size
        height: (dot.round ? 0 : Math.abs(dot.leadY - dot.trailY)) + dot.size
        radius: dot.size / 2
        color: dot.color
        visible: dot.target !== null
        transformOrigin: Item.Center
        antialiasing: true
        transform: Scale {
            origin.x: pill.width / 2
            origin.y: pill.height / 2
            xScale: (dot.vertical ? 1 / dot.squish : dot.squish) * dot.lift
            yScale: (dot.vertical ? dot.squish : 1 / dot.squish) * dot.lift
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
}
