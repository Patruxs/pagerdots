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
// The dot is a single item that glides between cells when the desktop changes.
PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property real dimOpacity: 0.55            // opacity of the other desktops
    readonly property int currentIndex: vdi.desktopIds.indexOf(vdi.currentDesktop)
    readonly property string labelStyle: Plasmoid.configuration.labelStyle
    readonly property bool dotForCurrent: Plasmoid.configuration.dotForCurrent
    // Whether the current desktop is marked by the gliding dot (as opposed to its bold label).
    // The "blank" style has no label to show, so it always uses the dot.
    readonly property bool useDot: dotForCurrent || labelStyle === "blank"

    TaskManager.VirtualDesktopInfo { id: vdi }

    function labelFor(index) {
        return Labels.labelFor(labelStyle, index + 1);
    }

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
        id: view
        acceptedButtons: Qt.NoButton
        onWheel: wheel => root.step(wheel.angleDelta.y < 0 ? 1 : -1)
        implicitWidth: grid.implicitWidth
        implicitHeight: grid.implicitHeight
        Layout.minimumWidth: root.vertical ? 0 : grid.implicitWidth
        Layout.minimumHeight: root.vertical ? grid.implicitHeight : 0
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        // Bumped whenever the repeater adds or removes a cell, so bindings that
        // look cells up through itemAt() (which is not a notifying property) re-run.
        property int cellsRevision: 0
        readonly property Item currentCell: {
            void cellsRevision;
            return cells.itemAt(root.currentIndex);
        }

        FontMetrics { id: fm }

        GridLayout {
            id: grid
            anchors.fill: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            rowSpacing: 0
            columnSpacing: 0

            Repeater {
                id: cells
                model: vdi.numberOfDesktops
                onItemAdded: view.cellsRevision++
                onItemRemoved: view.cellsRevision++

                // Plasma tooltip with the desktop name; `location` keeps it outside the panel.
                delegate: PlasmaCore.ToolTipArea {
                    id: cell
                    location: Plasmoid.location
                    mainText: vdi.desktopNames[index] ?? ""
                    required property int index
                    readonly property bool isCurrent: index === root.currentIndex

                    Layout.fillHeight: !root.vertical
                    Layout.fillWidth: root.vertical
                    // Wide enough for the label (e.g. "VIII") plus breathing room.
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
                        text: root.labelFor(cell.index)
                        font.bold: cell.isCurrent && !root.useDot
                        // The label under the dot fades out; the dot glides in over it.
                        opacity: cell.isCurrent ? (root.useDot ? 0 : 1)
                               : (mouse.containsMouse ? 1 : root.dimOpacity)
                        scale: cell.isCurrent && root.useDot ? 0.6 : 1
                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
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

        // The current-desktop dot. One item for the whole widget, positioned over
        // the current cell, so a desktop change animates as a glide rather than a jump.
        Rectangle {
            id: dot
            readonly property Item target: view.currentCell
            readonly property int size: Math.max(4, Math.round(fm.height * 0.45))

            width: size
            height: size
            radius: size / 2
            color: Kirigami.Theme.textColor
            visible: root.useDot && target !== null
            x: target ? target.x + (target.width - width) / 2 : 0
            y: target ? target.y + (target.height - height) / 2 : 0
            transformOrigin: Item.Center

            // Glide with a fast start and soft landing. Enabled only after the first
            // layout so the dot does not fly in from the corner when the widget loads.
            Behavior on x {
                enabled: dot.ready
                NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutQuint }
            }
            Behavior on y {
                enabled: dot.ready
                NumberAnimation { duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutQuint }
            }

            property bool ready: false
            Component.onCompleted: Qt.callLater(() => ready = true)

            // On every desktop change the dot briefly swells, then settles.
            Connections {
                target: root
                function onCurrentIndexChanged() {
                    if (dot.ready) pulse.restart();
                }
            }
            SequentialAnimation {
                id: pulse
                NumberAnimation { target: dot; property: "scale"; to: 1.45; duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
                NumberAnimation { target: dot; property: "scale"; to: 1.0;  duration: Kirigami.Units.longDuration;  easing.type: Easing.OutBack }
            }
        }
    }
}
