// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Window
import "../contents/ui/Animations.js" as Animations
import "../contents/ui"

// Drives Dot.qml through every animation in Animations.MODES without a Plasma
// session: a move of two cells, a cut-in back to the first cell while that move is
// still in flight, and then a change to the next mode while *that* is still in
// flight. Any QML warning (a missing file, an unknown property, a binding loop, an
// exception in start()) is printed by the qml tool; `tests/run` fails on it. Pass
// `-- vertical` to lay the cells out top to bottom.
Window {
    id: win
    width: 160
    height: 32
    visible: true

    readonly property bool vertical: Qt.application.arguments.includes("vertical")
    readonly property var modes: Animations.MODES.map(m => m.id)
    property int mode: 0
    property int current: 0
    property int cellsRevision: 0
    property int stage: 0

    Grid {
        id: row
        anchors.centerIn: parent
        rows: win.vertical ? -1 : 1
        columns: win.vertical ? 1 : -1
        spacing: 6
        Repeater {
            id: cells
            model: 4
            onItemAdded: win.cellsRevision++
            onItemRemoved: win.cellsRevision++
            Item { width: 28; height: 24 }
        }
    }
    Dot {
        id: dot
        anchors.fill: row
        target: { void win.cellsRevision; return cells.itemAt(win.current); }
        animation: win.modes[Math.min(win.mode, win.modes.length - 1)]
        size: 7
        color: "white"
        unit: 100
        vertical: win.vertical
        hopSign: win.vertical ? 1 : -1
    }

    function check(what) {
        if (dot.animation !== "none" && !dot.anim) console.warn("FAIL " + win.modes[win.mode] + ": did not load");
        const pill = dot.pill;
        if (!pill.visible || isNaN(pill.x) || isNaN(pill.y) || isNaN(pill.width) || isNaN(pill.height)) {
            console.warn("FAIL " + win.modes[win.mode] + ": pill is " + (pill.visible ? "off the map" : "hidden") + " " + what);
        }
        if (dot.travel < 0 || isNaN(dot.travel)) console.warn("FAIL " + win.modes[win.mode] + ": travel is " + dot.travel);
    }

    Timer {
        interval: 60
        running: true
        repeat: true
        onTriggered: {
            switch (win.stage++) {
            case 0: win.current = 2; break;              // a move of two cells
            case 1: win.check("mid-move"); break;
            case 2: win.current = 0; break;              // cut in on it
            case 3: win.check("mid cut-in"); break;
            case 4:                                      // change mode mid-flight
                if (++win.mode >= win.modes.length) {
                    console.warn("smoke: " + win.modes.length + " modes" + (win.vertical ? ", vertical" : "") + ", done");
                    Qt.quit();
                }
                win.stage = 0;
                break;
            }
        }
    }
}
