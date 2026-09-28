// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus
import "Labels.js" as Labels
import "Animations.js" as Animations
import "Desktops.js" as Desktops

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int currentIndex: vdi.desktopIds.indexOf(vdi.currentDesktop)
    readonly property string labelStyle: Plasmoid.configuration.labelStyle
    readonly property bool dotForCurrent: Plasmoid.configuration.dotForCurrent
    readonly property int spacing: Plasmoid.configuration.spacing
    readonly property real dimOpacity: (Plasmoid.configuration.dimOpacity || 100) / 100
    readonly property real emptyOpacity: (Plasmoid.configuration.emptyOpacity || 100) / 100
    readonly property bool markOccupied: emptyOpacity < dimOpacity
    readonly property bool dotStyle: Labels.drawsDots(labelStyle)
    readonly property string dotAnimation:
        dotStyle && !Plasmoid.configuration.pillCustomAnimation ? Animations.PILL_ANIMATION
                                                                : Animations.normalize(Plasmoid.configuration.dotAnimation)
    readonly property color dotColor: Plasmoid.configuration.dotColor === "accent"
                                      ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
    readonly property bool animated: dotAnimation !== "none"
    readonly property int animationUnit:
        Animations.unitFor(Kirigami.Units.longDuration, Plasmoid.configuration.animationSpeed)
    readonly property bool useDot: Labels.usesDot(labelStyle, dotForCurrent)

    readonly property bool wheelSwitches: Plasmoid.configuration.wheelSwitches
    readonly property bool wheelWrap: Plasmoid.configuration.wheelWrap
    readonly property bool wheelInvert: Plasmoid.configuration.wheelInvert
    readonly property string currentDesktopClick: Plasmoid.configuration.currentDesktopClick
    readonly property bool clickAnywhere: currentDesktopClick !== "nothing"
                                          && Plasmoid.configuration.currentDesktopClickAnywhere
    readonly property bool tooltips: Plasmoid.configuration.tooltips
    readonly property bool tooltipWindows: Plasmoid.configuration.tooltipWindows
    readonly property bool manageDesktops: Plasmoid.configuration.manageDesktops
    readonly property bool renameDesktop: Plasmoid.configuration.renameDesktop
    readonly property bool autoDesktops: Plasmoid.configuration.autoDesktops

    TaskManager.VirtualDesktopInfo { id: vdi }

    Loader {
        id: windows
        active: root.tooltipWindows || root.autoDesktops || root.markOccupied
        sourceComponent: DesktopWindows {}
        readonly property var titles: item?.titles ?? ({})
    }

    readonly property var desktopState: [windows.titles, vdi.desktopIds, currentIndex, autoDesktops]
    onDesktopStateChanged: if (autoDesktops) autoTidy.restart()
    Timer {
        id: autoTidy
        interval: 500
        onTriggered: root.tidyDesktops()
    }

    function isOccupied(index) {
        if (!markOccupied || !windows.item?.populated) return true;
        return (windows.titles[vdi.desktopIds[index]] ?? []).length > 0;
    }

    function labelFor(index) {
        return Labels.labelFor(labelStyle, index + 1, currentIndex + 1);
    }

    function tidyDesktops() {
        if (!autoDesktops || !windows.item?.settled) return;
        const todo = Desktops.plan(vdi.desktopIds, windows.titles, currentIndex);
        if (todo.create) createDesktop();
        todo.remove.forEach(removeDesktop);
    }

    function windowsOn(id) {
        const titles = windows.titles[id] ?? [];
        if (titles.length === 0) return i18n("No windows");
        const shown = titles.slice(0, 6);
        if (titles.length > shown.length) {
            shown.push(i18np("and one more", "and %1 more", titles.length - shown.length));
        }
        return shown.join("\n");
    }

    function switchTo(index) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/KWin", iface: "org.kde.KWin",
            member: "setCurrentDesktop", arguments: [new DBus.int32(index + 1)]
        });
    }

    function step(delta) {
        const n = vdi.numberOfDesktops;
        if (n < 1) return;
        const next = currentIndex + delta;
        if (wheelWrap) switchTo((next % n + n) % n);
        else if (next >= 0 && next < n) switchTo(next);
    }

    function desktopCall(member, args) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.KWin", path: "/VirtualDesktopManager",
            iface: "org.kde.KWin.VirtualDesktopManager", member: member, arguments: args
        });
    }
    function createDesktop() {
        const n = vdi.numberOfDesktops;
        const base = Plasmoid.configuration.newDesktopName.trim();
        desktopCall("createDesktop", [new DBus.uint32(n), base === "" ? "" : base + " " + (n + 1)]);
    }
    function removeDesktop(id) {
        desktopCall("removeDesktop", [id]);
    }
    function setDesktopName(id, name) {
        desktopCall("setDesktopName", [id, name]);
    }

    function clickCurrent() {
        const names = { showDesktop: "Show Desktop", overview: "Overview", grid: "Grid View" };
        const name = names[currentDesktopClick];
        if (!name) return;
        DBus.SessionBus.asyncCall({
            service: "org.kde.kglobalaccel", path: "/component/kwin",
            iface: "org.kde.kglobalaccel.Component", member: "invokeShortcut", arguments: [name]
        });
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Add Desktop")
            icon.name: "list-add"
            visible: root.manageDesktops && !root.autoDesktops
            onTriggered: root.createDesktop()
        },
        PlasmaCore.Action {
            text: i18n("Remove Last Desktop")
            icon.name: "edit-delete-remove"
            visible: root.manageDesktops && !root.autoDesktops
            enabled: vdi.numberOfDesktops > 1
            onTriggered: root.removeDesktop(vdi.desktopIds[vdi.desktopIds.length - 1])
        },
        PlasmaCore.Action {
            text: i18n("Rename Current Desktop…")
            icon.name: "edit-rename"
            visible: root.renameDesktop
            enabled: root.currentIndex >= 0
            onTriggered: renameDialog.open()
        },
        PlasmaCore.Action {
            text: i18n("Configure Virtual Desktops…")
            icon.name: "virtual-desktops"
            onTriggered: KCM.KCMLauncher.openSystemSettings("kcm_kwin_virtualdesktops")
        }
    ]

    PlasmaCore.Dialog {
        id: renameDialog
        visualParent: root
        location: Plasmoid.location
        type: PlasmaCore.Dialog.AppletPopup
        hideOnWindowDeactivate: true

        function open() {
            nameField.text = vdi.desktopNames[root.currentIndex] ?? "";
            visible = true;
            nameField.forceActiveFocus();
            nameField.selectAll();
        }
        function apply() {
            const name = nameField.text.trim();
            if (name !== "" && root.currentIndex >= 0) root.setDesktopName(vdi.currentDesktop, name);
            visible = false;
        }

        mainItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Keys.onEscapePressed: renameDialog.visible = false

            QQC2.Label {
                text: i18n("Rename desktop %1:", root.currentIndex + 1)
            }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.TextField {
                    id: nameField
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                    onAccepted: renameDialog.apply()
                }
                QQC2.Button {
                    text: i18n("Rename")
                    icon.name: "edit-rename"
                    enabled: nameField.text.trim() !== ""
                    onClicked: renameDialog.apply()
                }
            }
        }
    }

    preferredRepresentation: fullRepresentation

    fullRepresentation: MouseArea {
        id: view
        acceptedButtons: Qt.NoButton
        property int wheelDelta: 0
        onWheel: wheel => {
            if (!root.wheelSwitches) { wheel.accepted = false; return; }
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            if (delta * wheelDelta < 0) wheelDelta = 0;
            wheelDelta += delta;
            const dir = root.wheelInvert ? 1 : -1;
            while (wheelDelta >= 120) { wheelDelta -= 120; root.step(dir); }
            while (wheelDelta <= -120) { wheelDelta += 120; root.step(-dir); }
        }

        implicitWidth: grid.implicitWidth + (root.vertical ? 0 : elongation + padding * 2)
        implicitHeight: grid.implicitHeight + (root.vertical ? elongation + padding * 2 : 0)
        Layout.minimumWidth: root.vertical ? 0 : implicitWidth
        Layout.minimumHeight: root.vertical ? implicitHeight : 0
        Layout.preferredWidth: Layout.minimumWidth
        Layout.preferredHeight: Layout.minimumHeight

        property int cellsRevision: 0
        readonly property Item currentCell: {
            void cellsRevision;
            return cells.itemAt(root.currentIndex);
        }

        FontMetrics { id: fm; font: Kirigami.Theme.defaultFont }

        readonly property real dotSize:
            Math.max(4, Math.round(fm.height * (root.dotStyle ? Labels.PILL_DOT : 0.45)))
        readonly property real elongation: root.dotStyle ? Math.round(dotSize * (Labels.PILL_LENGTH - 1)) : 0
        readonly property real padding: Math.round(dotSize * 0.8)

        readonly property int gap: root.dotStyle && !Plasmoid.configuration.pillCustomSpacing
                                   ? Math.round(dotSize * Labels.PILL_GAP) : root.spacing

        readonly property real cellWidth: {
            let widest = 0;
            for (let i = 0; i < vdi.numberOfDesktops; i++) {
                widest = Math.max(widest, fm.advanceWidth(root.labelFor(i)));
            }
            return Math.max(Kirigami.Units.gridUnit * 1.4, Math.ceil(widest) + Kirigami.Units.largeSpacing);
        }

        readonly property real cellLength: root.dotStyle ? Math.round(dotSize * Labels.DOT_CELL)
                                         : root.vertical ? Kirigami.Units.gridUnit * 1.4 : cellWidth

        Item {
            id: content
            anchors.centerIn: parent
            width: root.vertical ? view.width : view.implicitWidth
            height: root.vertical ? view.implicitHeight : view.height

            HoverHandler { id: hover }

            MouseArea {
                anchors.fill: parent
                enabled: root.clickAnywhere
                acceptedButtons: Qt.LeftButton
                onClicked: root.clickCurrent()
            }

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

                    delegate: Item {
                        id: cell
                        required property int index
                        readonly property bool isCurrent: index === root.currentIndex

                        Layout.fillHeight: !root.vertical
                        Layout.fillWidth: root.vertical
                        Layout.minimumWidth: root.vertical ? 0 : view.cellLength
                        Layout.minimumHeight: root.vertical ? view.cellLength : 0

                        readonly property real slide: index < root.currentIndex ? 0
                                                    : index === root.currentIndex ? view.elongation / 2
                                                    : view.elongation

                        PlasmaCore.ToolTipArea {
                            id: body
                            active: root.tooltips
                            location: Plasmoid.location
                            mainText: vdi.desktopNames[cell.index] ?? ""
                            subText: root.tooltipWindows ? root.windowsOn(vdi.desktopIds[cell.index]) : ""
                            x: root.vertical ? 0 : cell.slide
                            y: root.vertical ? cell.slide : 0
                            width: cell.width
                            height: cell.height
                            Behavior on x { enabled: root.animated; NumberAnimation { duration: dot.travel; easing.type: Easing.OutCubic } }
                            Behavior on y { enabled: root.animated; NumberAnimation { duration: dot.travel; easing.type: Easing.OutCubic } }

                            DesktopLabel {
                                anchors.fill: parent
                                text: root.labelFor(cell.index)
                                dotSize: root.dotStyle ? view.dotSize : 0
                                current: cell.isCurrent
                                underDot: cell.isCurrent && root.useDot
                                hovered: mouse.containsMouse
                                occupied: root.isOccupied(cell.index)
                                dimOpacity: root.dimOpacity
                                emptyOpacity: root.emptyOpacity
                                animated: root.animated
                                travel: dot.travel
                            }
                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: cell.isCurrent ? root.clickCurrent() : root.switchTo(cell.index)
                            }
                        }
                    }
                }
            }

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
                hopSign: !root.vertical ? -1
                       : Plasmoid.location === PlasmaCore.Types.LeftEdge ? 1 : -1
                visible: root.useDot
            }
        }
    }
}
