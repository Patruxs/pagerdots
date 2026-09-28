// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.taskmanager as TaskManager

Item {
    id: windows
    visible: false

    property var titles: ({})
    property bool settled: false
    readonly property bool populated: settled || Object.keys(titles).length > 0

    Timer { interval: 3000; running: true; onTriggered: windows.settled = true }

    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: false
        filterMinimized: false
        groupMode: TaskManager.TasksModel.GroupDisabled

        onRowsInserted: refresh.restart()
        onRowsRemoved: refresh.restart()
        onModelReset: refresh.restart()
        onDataChanged: refresh.restart()
    }
    Timer {
        id: refresh
        interval: 150
        running: true
        onTriggered: windows.update()
    }

    function update() {
        const map = {};
        for (let row = 0; row < tasks.count; row++) {
            const index = tasks.index(row, 0);
            if (!tasks.data(index, TaskManager.AbstractTasksModel.IsWindow)
                || tasks.data(index, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops)) continue;
            const title = tasks.data(index, Qt.DisplayRole);
            for (const id of tasks.data(index, TaskManager.AbstractTasksModel.VirtualDesktops) ?? []) {
                if (!map[id]) map[id] = [];
                map[id].push(title);
            }
        }
        titles = map;
    }
}
