// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.taskmanager as TaskManager

Item {
    id: windows
    visible: false

    property var titles: ({})
    property var screenTitles: ({})
    property rect screenGeometry
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
    TaskManager.TasksModel {
        id: screenTasks
        screenGeometry: windows.screenGeometry
        filterByVirtualDesktop: false
        filterByScreen: true
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

    function collect(model) {
        const map = {};
        for (let row = 0; row < model.count; row++) {
            const index = model.index(row, 0);
            if (!model.data(index, TaskManager.AbstractTasksModel.IsWindow)
                || model.data(index, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops)) continue;
            const title = model.data(index, Qt.DisplayRole);
            for (const id of model.data(index, TaskManager.AbstractTasksModel.VirtualDesktops) ?? []) {
                if (!map[id]) map[id] = [];
                map[id].push(title);
            }
        }
        return map;
    }

    function update() {
        titles = collect(tasks);
        screenTitles = collect(screenTasks);
    }
}
