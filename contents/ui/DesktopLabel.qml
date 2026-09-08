// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// The label of one desktop: dimmed unless it is the current desktop or hovered, bold
// when it marks the current desktop itself, and ducked out of sight while the dot
// sits on it. Used by the widget and, so that the two never drift apart, by the
// preview on the settings page.
QQC2.Label {
    id: label

    property bool current: false
    // Whether the dot marks this desktop right now, in which case the label hides under it.
    property bool underDot: false
    property bool hovered: false
    // Whether to animate at all, and how long the dot takes to reach its new cell
    // (Dot.travel), which is how long the label waits before coming back.
    property bool animated: true
    property int travel: 0
    readonly property real dimOpacity: 0.55     // opacity of the other desktops

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    color: Kirigami.Theme.textColor
    font.bold: current && !underDot

    // 1 while the label is on show, 0 while the dot covers it.
    property real shown: underDot ? 0 : 1
    property real emphasis: current || hovered ? 1 : dimOpacity
    opacity: shown * emphasis
    scale: 0.6 + 0.4 * shown

    // The label ducks quickly under the arriving dot, and comes back slowly enough
    // that the dot has left before it shows again.
    Behavior on shown {
        id: shownBehavior
        enabled: label.animated
        NumberAnimation {
            duration: shownBehavior.targetValue === 0 ? Kirigami.Units.longDuration : label.travel
            easing.type: shownBehavior.targetValue === 0 ? Easing.OutCubic : Easing.InCubic
        }
    }
    Behavior on emphasis {
        enabled: label.animated
        NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
    }
}
