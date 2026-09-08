// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "loop": loops the loop on the way over. Along the row to the near side of a circle
// between the cells, once round it at a steady pace (forward over the top, back
// underneath) and on along the row: the circle gets most of the time, however far
// the move is.
PathDotAnimation {
    duration: dot.unit * 2.6

    function pathPoint(t) {
        const dist = Math.abs(shift);
        const reach = dot.room;
        const inLeg = Math.max(0, dist / 2 - reach);
        if (t < 0.2) { const f = t / 0.2; return [inLeg * f * f, 0]; }
        if (t < 0.75) {
            const a = 2 * Math.PI * (t - 0.2) / 0.55;
            return [inLeg + reach - reach * Math.cos(a), reach * Math.sin(a)];
        }
        const f = (t - 0.75) / 0.25;
        return [inLeg + (dist - inLeg) * (1 - (1 - f) * (1 - f)), 0];
    }
}
