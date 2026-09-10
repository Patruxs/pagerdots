// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.taskmanager as TaskManager

// Which windows are on which virtual desktop, from the task manager's model:
// `titles` maps a desktop id to the titles of the windows on it. Windows on every
// desktop are left out, so a desktop with only those counts as empty. Used for the
// window list in the tooltip and for the automatic desktops, and loaded only while
// one of those is in use, since the model is not free.
Item {
    id: windows
    visible: false

    property var titles: ({})
    // Whether the model has had time to fill in. Right after loading it may still be
    // empty, and anything acting on that (removing every desktop, say) must wait.
    property bool settled: false

    Timer { interval: 3000; running: true; onTriggered: windows.settled = true }

    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: false
        filterByScreen: false
        filterByActivity: false
        filterMinimized: false
        groupMode: TaskManager.TasksModel.GroupDisabled

        // A change of any kind (a window opening, closing, moving to another desktop
        // or retitled) refreshes the map, a moment later, so a burst is handled once.
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
