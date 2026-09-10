// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// The GNOME-style rule for the automatic desktops: there is always exactly one empty
// desktop after the last one with windows. Given the desktop ids in order, the map of
// desktop id to window titles (see DesktopWindows.qml) and the current desktop's
// index, returns what to do: whether to add a desktop at the end (the last one has
// windows), and which desktops to remove (empty ones other than the one kept at the
// end and the current one, which goes once it is left), last first.
function plan(ids, titles, currentIndex) {
    const empty = ids.map(id => !(titles[id]?.length > 0));
    const keep = empty.lastIndexOf(false) + 1;
    const remove = [];
    for (let i = ids.length - 1; i >= 0; i--) {
        if (empty[i] && i !== keep && i !== currentIndex) remove.push(ids[i]);
    }
    return { create: ids.length > 0 && !empty[ids.length - 1], remove };
}
