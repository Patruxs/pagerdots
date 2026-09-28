// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

DotAnimation {
    leadDuration: dot.unit * 1.5
    trailDuration: dot.unit * 2.25
    trailEasing: Easing.InOutQuart
}
