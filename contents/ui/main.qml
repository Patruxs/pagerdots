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
    // Whether the other desktops are drawn as dots, with the current one a pill (the
    // "pill" style), rather than labelled.
    readonly property bool dotStyle: Labels.drawsDots(labelStyle)
    // The pill style keeps its own animation unless customised.
    readonly property string dotAnimation:
        dotStyle && !Plasmoid.configuration.pillCustomAnimation ? Animations.PILL_ANIMATION
                                                                : Animations.normalize(Plasmoid.configuration.dotAnimation)
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
        // The row, plus the room the pill takes up in the pill style, and the padding
        // at either end.
        implicitWidth: grid.implicitWidth + (root.vertical ? 0 : elongation + padding * 2)
        implicitHeight: grid.implicitHeight + (root.vertical ? elongation + padding * 2 : 0)
        Layout.minimumWidth: root.vertical ? 0 : implicitWidth
        Layout.minimumHeight: root.vertical ? implicitHeight : 0
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

        // The dot is a little under half the text height, so it sits well among the
        // labels; the dots of the pill style, which stand on their own, are bigger.
        readonly property real dotSize:
            Math.max(4, Math.round(fm.height * (root.dotStyle ? Labels.PILL_DOT : 0.45)))
        // How much longer than it is thick the dot is at rest: the pill of the pill
        // style, or nothing. The row is that much longer than its cells, and what each
        // cell shows slides along to make room for the pill wherever it is (see `slide`
        // below), the way a page indicator does.
        readonly property real elongation: root.dotStyle ? Math.round(dotSize * (Labels.PILL_LENGTH - 1)) : 0
        // Room at either end of the row, so that the background shown while the mouse
        // is over the widget clears the labels: a snug fit, as GNOME's is.
        readonly property real padding: Math.round(dotSize * 0.8)

        // The gap between cells: the pill style's own unless customised, else the setting.
        readonly property int gap: root.dotStyle && !Plasmoid.configuration.pillCustomSpacing
                                   ? Math.round(dotSize * Labels.PILL_GAP) : root.spacing

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
        // The size of a cell along the row: that width, or the standard height when the
        // row runs down the panel. The dots of the pill style sit closer together.
        readonly property real cellLength: root.dotStyle ? Math.round(dotSize * Labels.DOT_CELL)
                                         : root.vertical ? Kirigami.Units.gridUnit * 1.4 : cellWidth

        // The row, its background and the dot, kept together in the middle of whatever
        // the panel allots the widget, which may be more than it asked for.
        Item {
            id: content
            anchors.centerIn: parent
            width: root.vertical ? view.width : view.implicitWidth
            height: root.vertical ? view.implicitHeight : view.height

            // Whether the mouse is over the widget. On this plain item rather than on
            // the MouseArea above: a pointer handler makes its item accept every mouse
            // button, and a MouseArea then swallows the right clicks that Plasma needs
            // for the widget's context menu.
            HoverHandler { id: hover }

            // The background while the mouse is over the widget, a pill as in GNOME: as
            // tall (or, down a panel, as wide) as the cells with a little extra, and as
            // long as the row with its padding.
            Rectangle {
                readonly property real thickness:
                    Math.min(root.vertical ? view.width : view.height,
                             Kirigami.Units.gridUnit * 1.4 + Kirigami.Units.smallSpacing * 2)
                anchors.centerIn: parent
                width: root.vertical ? thickness : content.width
                height: root.vertical ? content.height : thickness
                radius: thickness / 2
                color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                opacity: hover.hovered ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
            }

            GridLayout {
                id: grid
                anchors.fill: parent
                anchors.leftMargin: root.vertical ? 0 : view.padding
                anchors.rightMargin: root.vertical ? 0 : view.elongation + view.padding
                anchors.topMargin: root.vertical ? view.padding : 0
                anchors.bottomMargin: root.vertical ? view.elongation + view.padding : 0
                rows: root.vertical ? -1 : 1
                columns: root.vertical ? 1 : -1
                rowSpacing: root.vertical ? view.gap : 0
                columnSpacing: root.vertical ? 0 : view.gap

                Repeater {
                    id: cells
                    model: vdi.numberOfDesktops
                    onItemAdded: view.cellsRevision++
                    onItemRemoved: view.cellsRevision++

                    // The cell itself only takes up space; the dot is laid over it. What it
                    // shows is in `body`, which slides along the row in the pill style.
                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property bool isCurrent: index === root.currentIndex

                        // Across the row the cells take whatever the panel gives, and no
                        // more: a minimum the panel cannot meet would make the row overflow
                        // it, and everything centred on the cells sit below the panel's centre.
                        Layout.fillHeight: !root.vertical
                        Layout.fillWidth: root.vertical
                        Layout.minimumWidth: root.vertical ? 0 : view.cellLength
                        Layout.minimumHeight: root.vertical ? view.cellLength : 0

                        // How far along the row the cell's contents sit past the cell: the
                        // room the pill takes up. Cells before the current desktop stay put,
                        // the ones after it move over by the pill's extra length, and the
                        // current one by half of it (the pill, offset the same way, then
                        // starts where its dot would have been).
                        readonly property real slide: index < root.currentIndex ? 0
                                                    : index === root.currentIndex ? view.elongation / 2
                                                    : view.elongation

                        // Plasma tooltip with the desktop name; `location` keeps it outside the panel.
                        PlasmaCore.ToolTipArea {
                            id: body
                            location: Plasmoid.location
                            mainText: vdi.desktopNames[cell.index] ?? ""
                            x: root.vertical ? 0 : cell.slide
                            y: root.vertical ? cell.slide : 0
                            width: cell.width
                            height: cell.height
                            // Moves over in step with the dot arriving.
                            Behavior on x { enabled: root.animated; NumberAnimation { duration: dot.travel; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: root.animated; NumberAnimation { duration: dot.travel; easing.type: Easing.OutCubic } }

                            DesktopLabel {
                                anchors.fill: parent
                                text: root.labelFor(cell.index)
                                dotSize: root.dotStyle ? view.dotSize : 0
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
            }

            // The current-desktop dot. One item for the whole widget, laid over the
            // current cell, so a desktop change animates instead of jumping. It shares the
            // grid's coordinates, so it is shifted along the row by the grid's padding, and
            // in the pill style by half the pill's extra length as well, like the current
            // cell's contents, so the pill starts where its dot would have been.
            Dot {
                id: dot
                anchors.fill: parent
                anchors.leftMargin: root.vertical ? 0 : view.padding + view.elongation / 2
                anchors.rightMargin: -anchors.leftMargin
                anchors.topMargin: root.vertical ? view.padding + view.elongation / 2 : 0
                anchors.bottomMargin: -anchors.topMargin
                target: view.currentCell
                animation: root.dotAnimation
                size: view.dotSize
                elongation: view.elongation
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
}
