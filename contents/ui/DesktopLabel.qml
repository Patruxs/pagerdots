// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// The label of one desktop: dimmed unless it is the current desktop or hovered (and
// dimmed further if it has no windows, when desktops in use are marked), bold when it
// marks the current desktop itself, and ducked out of sight while the dot sits on it.
// Used by the widget and, so that the two never drift apart, by the preview on the
// settings page.
QQC2.Label {
    id: label

    property bool current: false
    // Whether the dot marks this desktop right now, in which case the label hides under it.
    property bool underDot: false
    property bool hovered: false
    // Whether the desktop has windows on it. Only told apart when the widget marks the
    // desktops in use; otherwise every desktop counts as occupied, and looks as it did.
    property bool occupied: true
    // Diameter of a plain dot drawn in place of the text (for the "pill" style), or 0
    // to show the text.
    property real dotSize: 0
    // Whether to animate at all, and how long the dot takes to reach its new cell
    // (Dot.travel), which is how long the label waits before coming back.
    property bool animated: true
    property int travel: 0
    // Opacity of the other desktops, and of those with no windows, if marked; both set
    // from the widget's configuration.
    property real dimOpacity: 1
    property real emptyOpacity: 1

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    color: Kirigami.Theme.textColor
    font.bold: current && !underDot

    // 1 while the label is on show, 0 while the dot covers it.
    property real shown: underDot ? 0 : 1
    property real emphasis: current || hovered ? 1 : occupied ? dimOpacity : emptyOpacity
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

    // The dot of the "pill" style, drawn in the text colour so it dims and brightens
    // with the label.
    Rectangle {
        anchors.centerIn: parent
        width: label.dotSize
        height: label.dotSize
        radius: label.dotSize / 2
        color: label.color
        visible: label.dotSize > 0
        antialiasing: true
    }
}
