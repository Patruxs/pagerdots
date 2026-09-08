// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus
import "Labels.js" as Labels
import "Animations.js" as Animations

// Pager Dots: a dot for the current virtual desktop, dimmed labels for the others.
// Click a desktop to switch, mouse wheel to step. Label style and the animation
// the dot makes between desktops are configurable.
PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int currentIndex: vdi.desktopIds.indexOf(vdi.currentDesktop)
    readonly property string labelStyle: Plasmoid.configuration.labelStyle
    readonly property bool dotForCurrent: Plasmoid.configuration.dotForCurrent
    readonly property int spacing: Plasmoid.configuration.spacing
    readonly property string dotAnimation: Animations.normalize(Plasmoid.configuration.dotAnimation)
    // The dot is drawn in the text colour, or the accent colour if so configured.
    readonly property color dotColor: Plasmoid.configuration.dotColor === "accent"
                                      ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
    readonly property bool animated: dotAnimation !== "none"
    readonly property int animationUnit:
        Animations.unitFor(Kirigami.Units.longDuration, Plasmoid.configuration.animationSpeed)
    // Whether the current desktop is marked by the gliding dot (as opposed to its bold label).
    readonly property bool useDot: Labels.usesDot(labelStyle, dotForCurrent)

    TaskManager.VirtualDesktopInfo { id: vdi }

    function labelFor(index) {
        return Labels.labelFor(labelStyle, index + 1, currentIndex + 1);
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
        // Wheel notches come in steps of 120; touchpads and free-spinning wheels send
        // many smaller events instead, so the deltas are added up and one desktop is
        // stepped per full notch, rather than several per swipe.
        property int wheelDelta: 0
        onWheel: wheel => {
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            // A change of direction starts afresh, so the first notch back is not swallowed.
            if (delta * wheelDelta < 0) wheelDelta = 0;
            wheelDelta += delta;
            while (wheelDelta >= 120) { wheelDelta -= 120; root.step(-1); }
            while (wheelDelta <= -120) { wheelDelta += 120; root.step(1); }
        }
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

        FontMetrics { id: fm; font: Kirigami.Theme.defaultFont }

        // All cells share one width: the widest label of the current style (e.g. "VIII")
        // plus breathing room, so the row stays evenly spaced whatever the labels are.
        // Measured through the method rather than a TextMetrics property, which would
        // make this binding depend on a value it changes itself and so loop.
        readonly property real cellWidth: {
            let widest = 0;
            for (let i = 0; i < vdi.numberOfDesktops; i++) {
                widest = Math.max(widest, fm.advanceWidth(root.labelFor(i)));
            }
            return Math.max(Kirigami.Units.gridUnit * 1.4, Math.ceil(widest) + Kirigami.Units.largeSpacing);
        }

        GridLayout {
            id: grid
            anchors.fill: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            rowSpacing: root.vertical ? root.spacing : 0
            columnSpacing: root.vertical ? 0 : root.spacing

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
                    Layout.minimumWidth: view.cellWidth
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 1.4

                    DesktopLabel {
                        anchors.fill: parent
                        text: root.labelFor(cell.index)
                        current: cell.isCurrent
                        underDot: cell.isCurrent && root.useDot
                        hovered: mouse.containsMouse
                        animated: root.animated
                        travel: dot.travel
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

        // The current-desktop dot. One item for the whole widget, laid over the
        // current cell, so a desktop change animates instead of jumping.
        Dot {
            id: dot
            anchors.fill: parent
            target: view.currentCell
            animation: root.dotAnimation
            size: Math.max(4, Math.round(fm.height * 0.45))
            color: root.dotColor
            unit: root.animationUnit
            vertical: root.vertical
            // "hop" jumps upwards in a horizontal panel, and away from the screen
            // edge (towards the desktop) in a vertical one.
            hopSign: !root.vertical ? -1
                   : Plasmoid.location === PlasmaCore.Types.LeftEdge ? 1 : -1
            visible: root.useDot
        }
    }
}
