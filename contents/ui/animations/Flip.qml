// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "flip": the dot slides across while turning over like a coin, thinning to a sliver
// edge on and back, a full turn per cell crossed. The turn is counted in half turns:
// `flipBase` done when the move started and `flipTurns` to come.
PathDotAnimation {
    flatten: Math.max(0.18, Math.abs(Math.cos(Math.PI * (flipBase + flipTurns * pathT))))

    property real flipBase: 0
    property real flipTurns: 0

    function pathPoint(t) {
        return [Math.abs(shift) * dot.easeInOut(t), 0];
    }

    function start(old, target) {
        flipBase += flipTurns * pathT;
        begin(old, target);
        // The coin lands face on: it turns on from where it is to the next whole turn
        // past a full turn per cell crossed.
        flipTurns = 2 * Math.min(2, cells) - (flipBase - Math.floor(flipBase));
    }
}
