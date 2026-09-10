// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

// The "Behavior" settings page: what the mouse does over the widget, what the tooltips
// show, and what the context menu offers for managing the desktops.
KCM.SimpleKCM {
    id: page

    property bool cfg_wheelSwitches
    property bool cfg_wheelWrap
    property bool cfg_wheelInvert
    property string cfg_currentDesktopClick
    property bool cfg_currentDesktopClickAnywhere
    property bool cfg_tooltips
    property bool cfg_tooltipWindows
    property bool cfg_manageDesktops
    property bool cfg_renameDesktop
    property bool cfg_autoDesktops
    property string cfg_newDesktopName

    // Plasma also hands the page the defaults from main.xml (for its "Defaults" button),
    // and warns if there is nowhere to put them.
    property var cfg_wheelSwitchesDefault
    property var cfg_wheelWrapDefault
    property var cfg_wheelInvertDefault
    property var cfg_currentDesktopClickDefault
    property var cfg_currentDesktopClickAnywhereDefault
    property var cfg_tooltipsDefault
    property var cfg_tooltipWindowsDefault
    property var cfg_manageDesktopsDefault
    property var cfg_renameDesktopDefault
    property var cfg_autoDesktopsDefault
    property var cfg_newDesktopNameDefault
    // The Appearance page's keys, for the same reason.
    property string cfg_labelStyle
    property bool cfg_dotForCurrent
    property string cfg_dotColor
    property int cfg_spacing
    property string cfg_dotAnimation
    property bool cfg_pillCustomAnimation
    property bool cfg_pillCustomSpacing
    property int cfg_animationSpeed
    property var cfg_labelStyleDefault
    property var cfg_dotForCurrentDefault
    property var cfg_dotColorDefault
    property var cfg_spacingDefault
    property var cfg_dotAnimationDefault
    property var cfg_pillCustomAnimationDefault
    property var cfg_pillCustomSpacingDefault
    property var cfg_animationSpeedDefault

    // The page's own settings, for the "Defaults" button in its header.
    readonly property var ownKeys: ["wheelSwitches", "wheelWrap", "wheelInvert", "currentDesktopClick", "currentDesktopClickAnywhere",
                                     "tooltips", "tooltipWindows", "manageDesktops", "renameDesktop", "autoDesktops", "newDesktopName"]
    function restoreDefaults() {
        for (const key of ownKeys) {
            const value = page["cfg_" + key + "Default"];
            if (value !== undefined) page["cfg_" + key] = value;
        }
    }
    actions: [
        Kirigami.Action {
            text: i18n("Defaults")
            icon.name: "edit-undo"
            onTriggered: page.restoreDefaults()
        }
    ]

    // What a click on the current desktop can do; the last three are KWin's own
    // shortcuts, invoked by name (see clickCurrent() in main.qml).
    readonly property var clickActions: [
        { value: "nothing", text: i18n("Nothing") },
        { value: "showDesktop", text: i18n("Show the desktop") },
        { value: "overview", text: i18n("Show the Overview") },
        { value: "grid", text: i18n("Show the desktop grid") }
    ]

    // A checkbox with an explanation on hover rather than under it, to keep the page short.
    component Option: QQC2.CheckBox {
        property string hint
        QQC2.ToolTip.text: hint
        QQC2.ToolTip.visible: hint !== "" && hovered
        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mouse")
        }
        Option {
            text: i18n("Scroll to switch desktops")
            checked: page.cfg_wheelSwitches
            onToggled: page.cfg_wheelSwitches = checked
        }
        Option {
            text: i18n("Wrap around")
            hint: i18n("Scrolling past the last desktop goes to the first, and the other way round.")
            enabled: page.cfg_wheelSwitches
            checked: page.cfg_wheelWrap
            onToggled: page.cfg_wheelWrap = checked
        }
        Option {
            text: i18n("Invert the direction")
            enabled: page.cfg_wheelSwitches
            checked: page.cfg_wheelInvert
            onToggled: page.cfg_wheelInvert = checked
        }
        QQC2.ComboBox {
            id: clickCombo
            Kirigami.FormData.label: i18n("Click current desktop:")
            model: page.clickActions
            textRole: "text"
            valueRole: "value"
            onActivated: page.cfg_currentDesktopClick = currentValue
            QQC2.ToolTip.text: i18n("What a click on the current desktop does. A click on any other desktop switches to it.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            // Picking an entry writes currentIndex directly, which would drop a binding
            // on it; the setting is followed by hand instead (for the "Defaults" button).
            function follow() { currentIndex = Math.max(0, indexOfValue(page.cfg_currentDesktopClick)); }
            Component.onCompleted: follow()
            Connections {
                target: page
                function onCfg_currentDesktopClickChanged() { clickCombo.follow(); }
            }
        }
        Option {
            text: i18n("Also from the space around the desktops")
            enabled: page.cfg_currentDesktopClick !== "nothing"
            checked: page.cfg_currentDesktopClickAnywhere
            onToggled: page.cfg_currentDesktopClickAnywhere = checked
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Tooltip")
        }
        Option {
            text: i18n("Desktop name")
            checked: page.cfg_tooltips
            onToggled: page.cfg_tooltips = checked
        }
        Option {
            text: i18n("Open windows")
            enabled: page.cfg_tooltips
            checked: page.cfg_tooltipWindows
            onToggled: page.cfg_tooltipWindows = checked
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Desktops")
        }
        // Adding and removing by hand is pointless while the desktops are managed
        // automatically (an added desktop would be removed again at once).
        Option {
            text: i18n("Add and remove from the right-click menu")
            enabled: !page.cfg_autoDesktops
            checked: page.cfg_manageDesktops
            onToggled: page.cfg_manageDesktops = checked
        }
        Option {
            text: i18n("Rename from the right-click menu")
            checked: page.cfg_renameDesktop
            onToggled: page.cfg_renameDesktop = checked
        }
        Option {
            text: i18n("Add and remove automatically (GNOME-style)")
            checked: page.cfg_autoDesktops
            onToggled: page.cfg_autoDesktops = checked
        }
        // Spelled out under the option, since what it does is not obvious from its name.
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 26
            font: Kirigami.Theme.smallFont
            opacity: 0.7
            wrapMode: Text.Wrap
            text: i18n("Keeps one empty desktop after the last one with windows: a window on the last desktop adds a new one, and empty desktops are removed once you leave them.")
        }
        QQC2.TextField {
            Kirigami.FormData.label: i18n("New desktop name:")
            placeholderText: i18n("Desktop")
            text: page.cfg_newDesktopName
            onTextEdited: page.cfg_newDesktopName = text
            QQC2.ToolTip.text: i18n("New desktops are numbered after it, as in “Desktop 3”. Leave it empty for KWin's default.")
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
        }
    }
}
