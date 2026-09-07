// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus
import "Labels.js" as Labels

// Pager Dots: a dot for the current virtual desktop, dimmed labels for the others.
// Click a desktop to switch, mouse wheel to step. Label style is configurable.
PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property string activeMark: "●"      // shown for the current desktop
    readonly property real dimOpacity: 0.55            // opacity of the other desktops
    readonly property int currentIndex: vdi.desktopIds.indexOf(vdi.currentDesktop)
    readonly property string labelStyle: Plasmoid.configuration.labelStyle
    readonly property bool dotForCurrent: Plasmoid.configuration.dotForCurrent

    function labelFor(index) {
        return Labels.labelFor(labelStyle, index + 1);
    }
    // The current desktop shows the dot when configured to, or when its style
    // has no label of its own (the "blank" style); otherwise its label in bold.
    function currentIsDot(index) {
        return dotForCurrent || labelFor(index) === "";
    }

    TaskManager.VirtualDesktopInfo { id: vdi }

    function switchTo(index) {
        // Plain JS numbers are silently dropped from the message inside plasmashell,
        // so the argument must be wrapped in the typed int32 helper.
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/KWin", iface: "org.kde.KWin",
            member: "setCurrentDesktop", arguments: [new DBus.int32(index + 1)]
        });
    }
    function step(delta) {
        const n = vdi.numberOfDesktops;
        if (n < 1) return;
        switchTo((currentIndex + delta + n) % n);
    }

    preferredRepresentation: fullRepresentation

    fullRepresentation: MouseArea {
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.step(wheel.angleDelta.y < 0 ? 1 : -1)
        implicitWidth: grid.implicitWidth
        implicitHeight: grid.implicitHeight
        Layout.minimumWidth: root.vertical ? 0 : grid.implicitWidth
        Layout.minimumHeight: root.vertical ? grid.implicitHeight : 0
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        GridLayout {
            id: grid
            anchors.fill: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                model: vdi.numberOfDesktops
                // Plasma tooltip with the desktop name; `location` keeps it outside the panel.
                delegate: PlasmaCore.ToolTipArea {
                    id: cell
                    location: Plasmoid.location
                    mainText: vdi.desktopNames[index] ?? ""
                    required property int index
                    readonly property bool isCurrent: index === root.currentIndex

                    Layout.fillHeight: !root.vertical
                    Layout.fillWidth: root.vertical
                    // Wide enough for the label (e.g. "VIII") plus breathing room,
                    // measured on the label itself so the cell keeps its width when
                    // it becomes the current desktop and turns into a dot.
                    Layout.minimumWidth: Math.max(Kirigami.Units.gridUnit * 1.4,
                                                  metrics.advanceWidth + Kirigami.Units.largeSpacing)
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 1.4

                    TextMetrics {
                        id: metrics
                        font: label.font
                        text: root.labelFor(cell.index)
                    }
                    PC3.Label {
                        id: label
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: cell.isCurrent && root.currentIsDot(cell.index) ? root.activeMark : root.labelFor(cell.index)
                        font.bold: cell.isCurrent && !root.currentIsDot(cell.index)
                        opacity: cell.isCurrent || mouse.containsMouse ? 1 : root.dimOpacity
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.switchTo(cell.index)
                    }
                }
            }
        }
    }
}
