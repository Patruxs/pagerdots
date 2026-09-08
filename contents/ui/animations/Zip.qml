// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "zip": off like a shot, streaking across as a fine line that is reeled back in.
// The trail is held on the old cell until the lead is well away, so the line is drawn
// out before it is reeled in, and the pill thins the further it is stretched.
DotAnimation {
    leadDuration: dot.unit * 1.25
    leadEasing: Easing.OutExpo
    trailDelay: dot.unit * 0.2
    trailDuration: dot.unit * 1.3
    trailEasing: Easing.InOutExpo
    thickness: dot.size * (1 - 0.55 * Math.min(1, dot.gap / (dot.size * 4)))
}
