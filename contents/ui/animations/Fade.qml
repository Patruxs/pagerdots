// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "fade": the ghost on the old cell and the dot on the new one cross-fade. When the
// dot rests as a pill (the "pill" label style), the ghost also shrinks back into a dot
// as the new pill grows out of one, the way a page indicator changes page.
DotAnimation {
    id: anim
    kind: "swap"
    travel: dot.unit * 1.25

    function start(old, target) {
        // The two pills change length on the sides that face each other: the ghost
        // shrinks towards where its dot sits once the row has made room for the new
        // pill, and the pill grows from where the new cell's dot was.
        const forward = dot.centreOf(target) > dot.centreOf(old);
        keep = forward ? 1 : -1;
        dot.placeGhost(old);
        dot.ghost.keep = forward ? -1 : 1;
        fade.restart();
    }

    // A pill keeps its colour while it shrinks and only dims once it is a dot again,
    // so the old desktop never looks empty while its own dot is still coming back.
    readonly property bool pill: dot.elongation > 0

    ParallelAnimation {
        id: fade
        SequentialAnimation {
            PropertyAction { target: anim.dot.ghost; property: "opacity"; value: 1 }
            PauseAnimation { duration: anim.pill ? anim.dot.unit * 0.5 : 0 }
            NumberAnimation {
                target: anim.dot.ghost; property: "opacity"; from: 1; to: 0
                duration: anim.dot.unit * (anim.pill ? 0.75 : 1.25)
                // Eased both ends for the pill, so it hands over to the dot coming back
                // beneath it without a dip.
                easing.type: anim.pill ? Easing.InOutQuad : Easing.OutCubic
            }
            PropertyAction { target: anim.dot.ghost; property: "visible"; value: false }
        }
        NumberAnimation { target: anim.dot.pill; property: "opacity"; from: 0; to: 1; duration: anim.dot.unit * 1.25; easing.type: Easing.OutCubic }
        NumberAnimation { target: anim.dot.ghost; property: "extent"; from: 1; to: 0; duration: anim.dot.unit; easing.type: Easing.OutQuad }
        NumberAnimation { target: anim; property: "extent"; from: 0; to: 1; duration: anim.dot.unit; easing.type: Easing.OutQuad }
    }
}
