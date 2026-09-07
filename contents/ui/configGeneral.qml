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

    Kirigami.FormLayout {
        // A miniature pager that cycles through four desktops on its own, so every
        // choice below can be seen in action before it is applied.
        Rectangle {
            id: preview
            Kirigami.FormData.label: i18n("Preview:")
            implicitWidth: previewRow.implicitWidth + Kirigami.Units.largeSpacing * 2
            implicitHeight: previewRow.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: Kirigami.Units.smallSpacing
            color: Kirigami.Theme.alternateBackgroundColor
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

            property int current: 0
            readonly property bool useDot: page.cfg_dotForCurrent || page.cfg_labelStyle === "blank"
            readonly property bool animated: page.cfg_dotAnimation !== "none"
            property int cellsRevision: 0
            readonly property Item currentCell: {
                void cellsRevision;
                return previewCells.itemAt(current);
            }

            Timer {
                interval: 1400
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
                            opacity: cell.isCurrent ? (preview.useDot ? 0 : 1) : 0.55
                            scale: cell.isCurrent && preview.useDot ? 0.6 : 1
                            Behavior on opacity {
                                enabled: preview.animated
                                NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
                            }
                            Behavior on scale {
                                enabled: preview.animated
                                NumberAnimation { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic }
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
                anchors.fill: previewRow
                target: preview.currentCell
                animation: page.cfg_dotAnimation
                size: Math.max(4, Math.round(fm.height * 0.45))
                color: Kirigami.Theme.textColor
                unit: Kirigami.Units.longDuration
                visible: preview.useDot
            }
        }

        Item { Kirigami.FormData.isSection: true }

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

        QQC2.ButtonGroup { id: animationGroup }

        // One radio button per dot animation, with a short description beside it.
        Repeater {
            model: Animations.MODES

            RowLayout {
                required property var modelData
                required property int index

                Kirigami.FormData.label: index === 0 ? i18n("Dot animation:") : ""
                enabled: preview.useDot
                spacing: Kirigami.Units.largeSpacing

                QQC2.RadioButton {
                    QQC2.ButtonGroup.group: animationGroup
                    text: i18n(modelData.name)
                    checked: page.cfg_dotAnimation === modelData.id
                    onToggled: if (checked) page.cfg_dotAnimation = modelData.id
                }
                QQC2.Label {
                    text: i18n(modelData.description)
                    opacity: 0.6
                }
            }
        }
    }
}
