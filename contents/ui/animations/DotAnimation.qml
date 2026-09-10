// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import ".." as UI

// Base of every dot animation in this directory. Dot.qml loads animations/<Name>.qml
// for the mode <name> (as listed in ../Animations.js), hands it the Dot, and calls
// start() whenever the dot has to move to another cell. The animation drives the dot
// through the hooks below, and draws any shapes of its own as children: it fills the
// Dot, so its children share the cells' coordinate space.
//
// What the Dot provides (see ../Dot.qml): `size`, `color`, `unit`, `vertical` and
// `hopSign`; the centre of the current cell in `cx`/`cy` and `centreOf()`; `room`, how
// far anything can go across the row and stay within the cell; the `pill`, which is
// the dot itself, and the `ghost`, a copy left on the old cell by `placeGhost()`; and
// for slides, the trackers `leadX`/`leadY` and `trailX`/`trailY` and the `gap`
// between them.
//
// To add an animation, copy the closest existing file under a new name and add its id
// to MODES in ../Animations.js. See "Adding an animation" in the README.
Item {
    id: base

    required property UI.Dot dot

    // How the dot gets from the old cell to the new one:
    //   "slide"  the trackers carry the pill across, and the animation adds flourishes
    //            on top through the hooks below (or nothing at all)
    //   "swap"   the trackers jump to the new cell; the animation draws the change in
    //            place, usually shrinking the ghost on the old cell and growing the pill
    //            on the new one, with something of its own in between
    //   "shift"  the trackers jump to the new cell; the animation moves the pill along
    //            the row itself through `along`
    property string kind: "slide"

    // How long the dot takes to leave the old cell and settle on the new one, so the
    // label underneath can time its return.
    property int travel: kind === "slide" ? Math.max(leadDuration, trailDelay + trailDuration)
                                          : dot.unit * 2

    // For "slide": how the two trackers move. The lead tracker heads the pill and the
    // trail one brings up its rear, so different timings stretch it (see Dot.qml).
    property int leadDuration: dot.unit * 2
    property int leadEasing: Easing.BezierSpline
    property int trailDelay: 0
    property int trailDuration: leadDuration
    property int trailEasing: leadEasing
    // For "slide": keep the pill round on the lead tracker instead of stretching it
    // to the trail one (the animation then draws the gap however it likes).
    property bool tethered: false
    // Thickness of the pill across the row.
    property real thickness: dot.size

    // Offsets and scales applied to the pill.
    property real along: 0      // offset along the row
    property real across: 0     // offset across the row, positive the way dot.hopSign points
    property real squish: 1     // scale along the row; the pill thins across it to compensate
    property real lift: 1       // uniform scale
    property real flatten: 1    // scale across the row only
    property real fade: 1       // opacity
    // How much of its resting length the pill has (see Dot.elongation; nothing to a
    // round dot), and which end of it stays put as it grows or shrinks: -1 the end
    // nearer the start of the row, 0 the middle, +1 the far end. The ghost has the
    // same two properties of its own.
    property real extent: 1
    property real keep: 0

    // Centre of the old cell, for animations that draw something between the two cells.
    property real fromX: 0
    property real fromY: 0
    // Record where this move starts from. A move that cuts in on one still in flight
    // passes how far along (0 to 1) whatever it draws has got from `fromX`/`fromY`
    // towards the old cell, so the new move sets off from where that is now rather
    // than from the old cell.
    function setFrom(old, progress = 1) {
        fromX += (old.x + old.width / 2 - fromX) * progress;
        fromY += (old.y + old.height / 2 - fromY) * progress;
    }

    // Called when the dot has to go from `old` to `target`, both cells and never the
    // same one. It may be called again before the move is over.
    function start(old, target) {}

    anchors.fill: parent
}
