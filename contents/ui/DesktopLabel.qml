// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami


QQC2.Label {
    id: label

    property bool current: false
   
    property bool underDot: false
    property bool hovered: false
   
    property bool occupied: true
   
    property real dotSize: 0
    
    property bool animated: true
    property int travel: 0
    
    property real dimOpacity: 1
    property real emptyOpacity: 1

    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    color: Kirigami.Theme.textColor
    font.bold: current && !underDot

    
    property real shown: underDot ? 0 : 1
    property real emphasis: current || hovered ? 1 : occupied ? dimOpacity : emptyOpacity
    opacity: shown * emphasis
    scale: 0.6 + 0.4 * shown

   
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
