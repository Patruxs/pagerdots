// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// "spring": slides over and wobbles into place like a spring.
DotAnimation {
    leadDuration: dot.unit * 2.75
    leadEasing: Easing.OutElastic
}
