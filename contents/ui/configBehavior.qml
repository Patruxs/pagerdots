// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM


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
   
    property string cfg_labelStyle
    property bool cfg_dotForCurrent
    property string cfg_dotColor
    property int cfg_spacing
    property int cfg_dimOpacity
    property int cfg_emptyOpacity
    property string cfg_dotAnimation
    property bool cfg_pillCustomAnimation
    property bool cfg_pillCustomSpacing
    property int cfg_animationSpeed
    property var cfg_labelStyleDefault
    property var cfg_dotForCurrentDefault
    property var cfg_dotColorDefault
    property var cfg_spacingDefault
    property var cfg_dimOpacityDefault
    property var cfg_emptyOpacityDefault
    property var cfg_dotAnimationDefault
    property var cfg_pillCustomAnimationDefault
    property var cfg_pillCustomSpacingDefault
    property var cfg_animationSpeedDefault

   
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

    
    readonly property var clickActions: [
        { value: "nothing", text: i18n("Nothing") },
        { value: "showDesktop", text: i18n("Show the desktop") },
        { value: "overview", text: i18n("Show the Overview") },
        { value: "grid", text: i18n("Show the desktop grid") }
    ]

    
    readonly property real formWidth: Kirigami.Units.gridUnit * 24

    
    component Hint: QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: page.formWidth
        leftPadding: scrollBox.leftPadding + scrollBox.indicator.width + scrollBox.spacing
        font: Kirigami.Theme.smallFont
        opacity: 0.7
        wrapMode: Text.Wrap
    }

    
    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: scrollBox
            Kirigami.FormData.label: i18n("Mouse wheel:")
            text: i18n("Switch desktops")
            checked: page.cfg_wheelSwitches
            onToggled: page.cfg_wheelSwitches = checked
        }
        QQC2.CheckBox {
            text: i18n("Wrap around at the first and last desktop")
            enabled: page.cfg_wheelSwitches
            checked: page.cfg_wheelWrap
            onToggled: page.cfg_wheelWrap = checked
        }
        QQC2.CheckBox {
            text: i18n("Invert the direction")
            enabled: page.cfg_wheelSwitches
            checked: page.cfg_wheelInvert
            onToggled: page.cfg_wheelInvert = checked
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            id: clickCombo
            Kirigami.FormData.label: i18n("Click on the current desktop:")
            Layout.fillWidth: true
            Layout.maximumWidth: page.formWidth
            model: page.clickActions
            textRole: "text"
            valueRole: "value"
            onActivated: page.cfg_currentDesktopClick = currentValue
            
            function follow() { currentIndex = Math.max(0, indexOfValue(page.cfg_currentDesktopClick)); }
            Component.onCompleted: follow()
            Connections {
                target: page
                function onCfg_currentDesktopClickChanged() { clickCombo.follow(); }
            }
        }
        QQC2.CheckBox {
            id: anywhereBox
            text: i18n("Also from the space around the desktops")
            enabled: page.cfg_currentDesktopClick !== "nothing"
            checked: page.cfg_currentDesktopClickAnywhere
            onToggled: page.cfg_currentDesktopClickAnywhere = checked
        }
        Hint {
            leftPadding: 0
            text: i18n("A click on any other desktop switches to it.")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Tooltip:")
            text: i18n("Show the desktop name")
            checked: page.cfg_tooltips
            onToggled: page.cfg_tooltips = checked
        }
        QQC2.CheckBox {
            text: i18n("List its open windows")
            enabled: page.cfg_tooltips
            checked: page.cfg_tooltipWindows
            onToggled: page.cfg_tooltipWindows = checked
        }

        Item { Kirigami.FormData.isSection: true }

        
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Right-click menu:")
            text: i18n("Add and remove desktops")
            enabled: !page.cfg_autoDesktops
            checked: page.cfg_manageDesktops
            onToggled: page.cfg_manageDesktops = checked
        }
        QQC2.CheckBox {
            text: i18n("Rename the current desktop")
            checked: page.cfg_renameDesktop
            onToggled: page.cfg_renameDesktop = checked
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Desktops:")
            text: i18n("Add and remove automatically (GNOME-style)")
            checked: page.cfg_autoDesktops
            onToggled: page.cfg_autoDesktops = checked
        }
        Hint {
            text: i18n("Keeps one empty desktop after the last one with windows: a window on the last desktop adds a new one, and empty desktops are removed once you leave them.")
        }
        QQC2.TextField {
            Kirigami.FormData.label: i18n("New desktop name:")
            Layout.fillWidth: true
            Layout.maximumWidth: page.formWidth
            placeholderText: i18n("Desktop")
            text: page.cfg_newDesktopName
            onTextEdited: page.cfg_newDesktopName = text
        }
        Hint {
            leftPadding: 0
            text: i18n("Numbered, as in “Desktop 3”. Leave it empty for KWin's default.")
        }
    }
}
