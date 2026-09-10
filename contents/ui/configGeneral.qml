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
    property string cfg_dotColor
    property int cfg_spacing
    property string cfg_dotAnimation
    property bool cfg_pillCustomAnimation
    property bool cfg_pillCustomSpacing
    // The pill style comes with the animation and the spacing of GNOME's page indicator
    // and keeps them, with those options locked, until the user chooses to customise
    // them (each on its own, after a warning).
    readonly property bool animationLocked: Labels.drawsDots(cfg_labelStyle) && !cfg_pillCustomAnimation
    readonly property bool spacingLocked: Labels.drawsDots(cfg_labelStyle) && !cfg_pillCustomSpacing
    // The animation to show and mark as selected: the pill style's own while locked,
    // otherwise the configured one, or the default one if that is no longer offered.
    readonly property string dotAnimation: animationLocked ? Animations.PILL_ANIMATION
                                                           : Animations.normalize(cfg_dotAnimation)
    property int cfg_animationSpeed

    // The animations in alphabetical order, arranged so that the two-column grid below
    // reads top to bottom: the first half of the list fills the left column, the rest
    // the right one. (The grid itself fills row by row.)
    readonly property var animationModes: {
        const sorted = [...Animations.MODES].sort((a, b) => i18n(a.name).localeCompare(i18n(b.name)));
        const rows = Math.ceil(sorted.length / 2);
        const ordered = [];
        for (let row = 0; row < rows; row++) {
            ordered.push(sorted[row]);
            if (row + rows < sorted.length) ordered.push(sorted[row + rows]);
        }
        return ordered;
    }
    // Plasma also hands the page the defaults from main.xml (for its "Defaults" button),
    // and warns if there is nowhere to put them.
    property var cfg_labelStyleDefault
    property var cfg_dotForCurrentDefault
    property var cfg_dotColorDefault
    property var cfg_spacingDefault
    property var cfg_dotAnimationDefault
    property var cfg_pillCustomAnimationDefault
    property var cfg_pillCustomSpacingDefault
    property var cfg_animationSpeedDefault

    // Asked before the pill style's animation or spacing is unlocked for customising.
    // `what` is which of the two; open it through ask().
    Kirigami.PromptDialog {
        id: customiseDialog
        property string what: "animation"
        function ask(what) {
            customiseDialog.what = what;
            open();
        }
        title: what === "spacing" ? i18n("Customize spacing?") : i18n("Customize animations?")
        subtitle: what === "spacing"
                  ? i18n("This spacing is part of the intended GNOME design. Modifying it will likely make the interface look worse. Proceed with caution.")
                  : i18n("This animation is part of the intended GNOME design. Modifying it will likely make the interface look worse. Proceed with caution.")
        standardButtons: Kirigami.Dialog.NoButton
        customFooterActions: [
            Kirigami.Action {
                text: i18n("Keep GNOME Style")
                onTriggered: customiseDialog.close()
            },
            Kirigami.Action {
                text: i18n("Customize Anyway")
                icon.name: "dialog-warning"
                onTriggered: {
                    if (customiseDialog.what === "spacing") page.cfg_pillCustomSpacing = true;
                    else page.cfg_pillCustomAnimation = true;
                    customiseDialog.close();
                }
            }
        ]
    }

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
                    implicitWidth: previewRow.implicitWidth + elongation + Kirigami.Units.largeSpacing * 2
                    implicitHeight: previewRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                    radius: Kirigami.Units.smallSpacing
                    color: Kirigami.Theme.alternateBackgroundColor
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)

                    property int current: 0
                    readonly property bool useDot: Labels.usesDot(page.cfg_labelStyle, page.cfg_dotForCurrent)
                    readonly property bool dotStyle: Labels.drawsDots(page.cfg_labelStyle)
                    // Sized like the widget's dot (see main.qml), with the pill style's
                    // bigger dots and the pill's extra length, which the row makes room for.
                    readonly property real dotSize:
                        Math.max(4, Math.round(fm.height * (dotStyle ? Labels.PILL_DOT : 0.45)))
                    readonly property real elongation: dotStyle ? Math.round(dotSize * (Labels.PILL_LENGTH - 1)) : 0
                    readonly property int gap: page.spacingLocked ? Math.round(dotSize * Labels.PILL_GAP) : page.cfg_spacing
                    readonly property bool animated: page.dotAnimation !== "none"
                    readonly property color dotColor: page.cfg_dotColor === "accent"
                                                      ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    readonly property int unit: Animations.unitFor(Kirigami.Units.longDuration, page.cfg_animationSpeed)
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
                    FontMetrics { id: fm; font: Kirigami.Theme.defaultFont }

                    Row {
                        id: previewRow
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -preview.elongation / 2
                        spacing: preview.gap

                        Repeater {
                            id: previewCells
                            model: 4
                            onItemAdded: preview.cellsRevision++
                            onItemRemoved: preview.cellsRevision++

                            Item {
                                id: cell
                                required property int index
                                readonly property bool isCurrent: index === preview.current

                                // Sized like the widget's cells: the label plus breathing room,
                                // or a couple of dots' worth in the pill style.
                                width: preview.dotStyle ? Math.round(preview.dotSize * Labels.DOT_CELL)
                                     : Math.max(Kirigami.Units.gridUnit * 1.4,
                                                Math.ceil(fm.advanceWidth(label.text)) + Kirigami.Units.largeSpacing)
                                height: Kirigami.Units.gridUnit * 1.4

                                // What the cell shows slides along to make room for the pill,
                                // as in the widget.
                                Item {
                                    x: cell.index < preview.current ? 0
                                     : cell.index === preview.current ? preview.elongation / 2
                                     : preview.elongation
                                    width: cell.width
                                    height: cell.height
                                    Behavior on x { enabled: preview.animated; NumberAnimation { duration: previewDot.travel; easing.type: Easing.OutCubic } }

                                    DesktopLabel {
                                        id: label
                                        anchors.fill: parent
                                        text: Labels.labelFor(page.cfg_labelStyle, cell.index + 1, preview.current + 1)
                                        dotSize: preview.dotStyle ? preview.dotSize : 0
                                        current: cell.isCurrent
                                        underDot: cell.isCurrent && preview.useDot
                                        animated: preview.animated
                                        travel: previewDot.travel
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: preview.current = cell.index
                                    }
                                }
                            }
                        }
                    }
                    Dot {
                        id: previewDot
                        anchors.fill: previewRow
                        anchors.leftMargin: preview.elongation / 2
                        anchors.rightMargin: -anchors.leftMargin
                        target: preview.currentCell
                        animation: page.dotAnimation
                        size: preview.dotSize
                        elongation: preview.elongation
                        color: preview.dotColor
                        unit: preview.unit
                        visible: preview.useDot
                    }
                }
            }

            // Speed as a percentage of Plasma's default animation speed. Up here with the
            // preview so it is the first thing seen and stays in view while scrolling.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                enabled: preview.useDot && preview.animated && !page.animationLocked
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

            // Dot colour and desktop spacing, kept up here with the preview so that their
            // effect is visible while they are changed.
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.largeSpacing

                QQC2.ButtonGroup { id: colorGroup }

                QQC2.Label {
                    text: i18n("Dot colour:")
                    enabled: preview.useDot
                }
                // The text colour blends in with the labels; the accent colour picks the
                // current desktop out in the colour scheme's highlight.
                QQC2.RadioButton {
                    enabled: preview.useDot
                    QQC2.ButtonGroup.group: colorGroup
                    text: i18n("Text colour")
                    checked: page.cfg_dotColor !== "accent"
                    onToggled: if (checked) page.cfg_dotColor = "text"
                }
                QQC2.RadioButton {
                    enabled: preview.useDot
                    QQC2.ButtonGroup.group: colorGroup
                    text: i18n("Accent colour")
                    checked: page.cfg_dotColor === "accent"
                    onToggled: if (checked) page.cfg_dotColor = "accent"
                }

                QQC2.Label {
                    Layout.leftMargin: Kirigami.Units.gridUnit
                    text: i18n("Space between desktops:")
                }
                // Shows the pill style's own gap while that is locked, and the setting
                // otherwise.
                QQC2.SpinBox {
                    enabled: !page.spacingLocked
                    from: 0
                    to: 40
                    stepSize: 1
                    value: page.spacingLocked ? preview.gap : page.cfg_spacing
                    onValueModified: page.cfg_spacing = value
                    textFromValue: (value, locale) => i18np("%1 pixel", "%1 pixels", value)
                    valueFromText: (text, locale) => parseInt(text) || 0
                }
                // Unlocks the spacing for the pill style (after a warning), or puts its
                // own spacing back once it has been customised.
                QQC2.ToolButton {
                    visible: Labels.drawsDots(page.cfg_labelStyle)
                    icon.name: page.spacingLocked ? "lock" : "edit-undo"
                    text: page.spacingLocked ? i18n("Customize…") : i18n("Use GNOME-style spacing")
                    display: page.spacingLocked ? QQC2.AbstractButton.IconOnly : QQC2.AbstractButton.TextBesideIcon
                    QQC2.ToolTip.text: page.spacingLocked ? i18n("Customize the space between desktops") : text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
                    onClicked: {
                        if (page.spacingLocked) customiseDialog.ask("spacing");
                        else page.cfg_pillCustomSpacing = false;
                    }
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
                    // The pill style is drawn, since no glyph looks like its pill.
                    QQC2.Label {
                        visible: !Labels.drawsDots(modelData.id)
                        text: modelData.preview
                        opacity: 0.6
                    }
                    Row {
                        id: pillPreview
                        visible: Labels.drawsDots(modelData.id)
                        readonly property real dot: Math.max(4, Math.round(fm.height * Labels.PILL_DOT))
                        spacing: Math.round(dot * Labels.PILL_GAP)
                        opacity: 0.6

                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                anchors.verticalCenter: parent.verticalCenter
                                width: index === 0 ? Math.round(pillPreview.dot * Labels.PILL_LENGTH) : pillPreview.dot
                                height: pillPreview.dot
                                radius: pillPreview.dot / 2
                                color: Kirigami.Theme.textColor
                                antialiasing: true
                            }
                        }
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
                text: page.animationLocked
                      ? i18n("The Pill style comes with the animation of GNOME's page indicator: the pill shrinks back into a dot as the new one grows.")
                      : i18n(Animations.MODES.find(m => m.id === page.dotAnimation)?.description ?? "")
                wrapMode: Text.Wrap
                opacity: 0.6
            }
            // Unlocks the options below for the pill style (after a warning), or puts
            // its own animation back once they have been customised.
            QQC2.Button {
                visible: Labels.drawsDots(page.cfg_labelStyle)
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                text: page.animationLocked ? i18n("Customize animation…") : i18n("Use GNOME-style animation")
                icon.name: page.animationLocked ? "lock" : "edit-undo"
                onClicked: {
                    if (page.animationLocked) customiseDialog.ask("animation");
                    else page.cfg_pillCustomAnimation = false;
                }
            }

            QQC2.ButtonGroup { id: animationGroup }

            // The dot animations as a two-column grid of radio buttons. Hovering one shows
            // its description; the preview above plays whichever is selected.
            GridLayout {
                enabled: preview.useDot && !page.animationLocked
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: 0

                Repeater {
                    model: page.animationModes

                    QQC2.RadioButton {
                        required property var modelData

                        QQC2.ButtonGroup.group: animationGroup
                        text: i18n(modelData.name)
                        checked: page.dotAnimation === modelData.id
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
