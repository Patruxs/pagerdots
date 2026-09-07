// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "Labels.js" as Labels
import "Animations.js" as Animations

KCM.SimpleKCM {
    id: page

    property string cfg_labelStyle
    property bool cfg_dotForCurrent
    property string cfg_dotAnimation
    property int cfg_animationSpeed

    // The preview lives in the page header rather than in the form, so it stays in
    // view while the options below are scrolled through.
    header: Item {
        implicitHeight: headerRow.implicitHeight + Kirigami.Units.largeSpacing * 2

        RowLayout {
            id: headerRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label { text: i18n("Preview:") }

            // A miniature pager that cycles through four desktops on its own, so every
            // choice below can be seen in action before it is applied.
            Rectangle {
                id: preview
                implicitWidth: previewRow.implicitWidth + Kirigami.Units.largeSpacing * 2
                implicitHeight: previewRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.alternateBackgroundColor
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                property int current: 0
                readonly property bool useDot: page.cfg_dotForCurrent || page.cfg_labelStyle === "blank"
                readonly property bool animated: page.cfg_dotAnimation !== "none"
                readonly property int unit:
                    Math.round(Kirigami.Units.longDuration * 100 / Math.max(25, page.cfg_animationSpeed))
                property int cellsRevision: 0
                readonly property Item currentCell: {
                    void cellsRevision;
                    return previewCells.itemAt(current);
                }

                // Long enough for the slowest animation to finish and rest a moment.
                Timer {
                    interval: Math.max(1400, previewDot.travel * 2 + 600)
                    running: preview.visible
                    repeat: true
                    onTriggered: preview.current = (preview.current + 1) % previewCells.count
                }
                FontMetrics { id: fm }

                Row {
                    id: previewRow
                    anchors.centerIn: parent

                    Repeater {
                        id: previewCells
                        model: 4
                        onItemAdded: preview.cellsRevision++
                        onItemRemoved: preview.cellsRevision++

                        Item {
                            id: cell
                            required property int index
                            readonly property bool isCurrent: index === preview.current

                            width: Math.max(Kirigami.Units.gridUnit * 1.4,
                                            metrics.advanceWidth + Kirigami.Units.largeSpacing)
                            height: Kirigami.Units.gridUnit * 1.4

                            TextMetrics {
                                id: metrics
                                font: label.font
                                text: label.text
                            }
                            QQC2.Label {
                                id: label
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: Labels.labelFor(page.cfg_labelStyle, cell.index + 1, preview.current + 1)
                                font.bold: cell.isCurrent && !preview.useDot
                                // Same timing as the widget: duck quickly under the arriving
                                // dot, come back only once it has left.
                                property real shown: cell.isCurrent && preview.useDot ? 0 : 1
                                opacity: shown * (cell.isCurrent ? 1 : 0.55)
                                scale: 0.6 + 0.4 * shown
                                Behavior on shown {
                                    id: shownBehavior
                                    enabled: preview.animated
                                    NumberAnimation {
                                        duration: shownBehavior.targetValue === 0 ? Kirigami.Units.longDuration : previewDot.travel
                                        easing.type: shownBehavior.targetValue === 0 ? Easing.OutCubic : Easing.InCubic
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: preview.current = cell.index
                            }
                        }
                    }
                }
                Dot {
                    id: previewDot
                    anchors.fill: previewRow
                    target: preview.currentCell
                    animation: page.cfg_dotAnimation
                    size: Math.max(4, Math.round(fm.height * 0.45))
                    color: Kirigami.Theme.textColor
                    backgroundColor: preview.color
                    unit: preview.unit
                    visible: preview.useDot
                }
            }
        }

        Kirigami.Separator {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        }
    }

    Kirigami.FormLayout {
        QQC2.ButtonGroup { id: styleGroup }

        // One radio button per style, with a dimmed preview of its labels beside it.
        Repeater {
            model: Labels.STYLES

            RowLayout {
                required property var modelData
                required property int index

                Kirigami.FormData.label: index === 0 ? i18n("Desktop labels:") : ""
                spacing: Kirigami.Units.largeSpacing

                QQC2.RadioButton {
                    QQC2.ButtonGroup.group: styleGroup
                    text: i18n(modelData.name)
                    checked: page.cfg_labelStyle === modelData.id
                    onToggled: if (checked) page.cfg_labelStyle = modelData.id
                }
                QQC2.Label {
                    text: modelData.preview
                    opacity: 0.6
                }
            }
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Current desktop:")
            text: i18n("Show as a dot instead of its label")
            checked: page.cfg_dotForCurrent
            onToggled: page.cfg_dotForCurrent = checked
        }

        Item { Kirigami.FormData.isSection: true }

        // The dot animations, with a description of the chosen one underneath. The
        // preview above plays it, so stepping through the list with the arrow keys or
        // the mouse wheel shows each in turn.
        QQC2.ComboBox {
            id: animationBox
            Kirigami.FormData.label: i18n("Dot animation:")
            enabled: preview.useDot
            model: Animations.MODES
            textRole: "name"
            valueRole: "id"
            currentIndex: Math.max(0, Animations.MODES.findIndex(m => m.id === page.cfg_dotAnimation))
            onActivated: page.cfg_dotAnimation = currentValue
        }
        QQC2.Label {
            Layout.preferredWidth: animationBox.width
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            enabled: preview.useDot
            text: i18n(Animations.MODES[animationBox.currentIndex]?.description ?? "")
            wrapMode: Text.Wrap
            opacity: 0.6
        }

        Item { Kirigami.FormData.isSection: true }

        // Speed as a percentage of Plasma's default animation speed.
        RowLayout {
            Kirigami.FormData.label: i18n("Animation speed:")
            enabled: preview.useDot && preview.animated
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                text: i18n("Slower")
                opacity: 0.6
            }
            QQC2.Slider {
                id: speedSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 50
                to: 200
                stepSize: 25
                snapMode: QQC2.Slider.SnapAlways
                value: page.cfg_animationSpeed
                onMoved: page.cfg_animationSpeed = value
            }
            QQC2.Label {
                text: i18n("Faster")
                opacity: 0.6
            }
            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                horizontalAlignment: Text.AlignRight
                text: i18nc("animation speed as a percentage", "%1%", page.cfg_animationSpeed)
            }
        }
    }
}
