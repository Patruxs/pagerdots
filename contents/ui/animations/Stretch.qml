// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "stretch": the lead tracker races ahead while the trail one lags, so the dot
// elongates into a pill towards the new desktop and then contracts onto it.
DotAnimation {
    leadDuration: dot.unit * 1.5
    trailDuration: dot.unit * 2.25
    trailEasing: Easing.InOutQuart
}
