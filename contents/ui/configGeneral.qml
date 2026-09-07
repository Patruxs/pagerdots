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
    property int cfg_spacing
    property string cfg_dotAnimation
    property int cfg_animationSpeed
    // Plasma also hands the page the defaults from main.xml (for its "Defaults" button),
    // and warns if there is nowhere to put them.
    property var cfg_labelStyleDefault
    property var cfg_dotForCurrentDefault
    property var cfg_spacingDefault
    property var cfg_dotAnimationDefault
    property var cfg_animationSpeedDefault

    // The preview lives in the page header rather than in the form, so it stays in
    // view while the options below are scrolled through.
    header: Item {
        implicitHeight: headerColumn.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: headerColumn
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
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
                        spacing: page.cfg_spacing

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

            // Speed as a percentage of Plasma's default animation speed. Up here with the
            // preview so it is the first thing seen and stays in view while scrolling.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                enabled: preview.useDot && preview.animated
                spacing: Kirigami.Units.largeSpacing

                QQC2.Label { text: i18n("Animation speed:") }
                QQC2.Label {
                    text: i18n("Slower")
                    opacity: 0.6
                }
                QQC2.Slider {
                    id: speedSlider
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
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

        Kirigami.Separator {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        }
    }

    // Two columns, so that the label styles and the dot options are visible together
    // without scrolling from one to the other. Plain columns with their own headings,
    // rather than form layouts, so the two headings line up exactly.
    RowLayout {
        spacing: Kirigami.Units.gridUnit * 3

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 0

            QQC2.Label {
                text: i18n("Desktop labels:")
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }

            QQC2.ButtonGroup { id: styleGroup }

            // One radio button per style, with a dimmed preview of its labels beside it.
            Repeater {
                model: Labels.STYLES

                RowLayout {
                    required property var modelData
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
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 0

            QQC2.Label {
                text: i18n("Current desktop:")
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }
            QQC2.CheckBox {
                text: i18n("Show as a dot instead of its label")
                checked: page.cfg_dotForCurrent
                onToggled: page.cfg_dotForCurrent = checked
            }

            QQC2.Label {
                text: i18n("Space between desktops:")
                Layout.topMargin: Kirigami.Units.largeSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }
            QQC2.SpinBox {
                from: 0
                to: 40
                stepSize: 1
                value: page.cfg_spacing
                onValueModified: page.cfg_spacing = value
                textFromValue: (value, locale) => i18np("%1 pixel", "%1 pixels", value)
                valueFromText: (text, locale) => parseInt(text) || 0
            }

            QQC2.Label {
                text: i18n("Dot animation:")
                Layout.topMargin: Kirigami.Units.largeSpacing
            }
            // What the selected animation does, right under the heading. It takes only
            // the height its own text needs, so short descriptions leave no gap.
            QQC2.Label {
                Layout.fillWidth: true
                Layout.maximumWidth: Kirigami.Units.gridUnit * 20
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                enabled: preview.useDot
                text: i18n(Animations.MODES.find(m => m.id === page.cfg_dotAnimation)?.description ?? "")
                wrapMode: Text.Wrap
                opacity: 0.6
            }

            QQC2.ButtonGroup { id: animationGroup }

            // The dot animations as a two-column grid of radio buttons. Hovering one shows
            // its description; the preview above plays whichever is selected.
            GridLayout {
                enabled: preview.useDot
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: 0

                Repeater {
                    model: Animations.MODES

                    QQC2.RadioButton {
                        required property var modelData

                        QQC2.ButtonGroup.group: animationGroup
                        text: i18n(modelData.name)
                        checked: page.cfg_dotAnimation === modelData.id
                        onToggled: if (checked) page.cfg_dotAnimation = modelData.id

                        QQC2.ToolTip.text: i18n(modelData.description)
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }
                }
            }
        }
    }
}
