// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

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
        flipTurns = 2 * Math.min(2, cells) - (flipBase - Math.floor(flipBase));
    }
}
