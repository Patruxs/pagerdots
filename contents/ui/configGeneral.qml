// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "Labels.js" as Labels

KCM.SimpleKCM {
    id: page

    property string cfg_labelStyle
    property bool cfg_dotForCurrent

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
    }
}
