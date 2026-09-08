// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "volley": over, batted straight back to the old cell, and over again to stay. Picks
// up speed on the way over, comes back at that speed, and sets off again with it to
// settle.
PathDotAnimation {
    duration: dot.unit * 2.4

    function pathPoint(t) {
        const dist = Math.abs(shift);
        if (t < 0.4) { const f = t / 0.4; return [dist * f * f, 0]; }
        if (t < 0.6) return [dist * (1 - (t - 0.4) / 0.2), 0];
        const f = (t - 0.6) / 0.4;
        return [dist * (1 - (1 - f) * (1 - f)), 0];
    }
}
