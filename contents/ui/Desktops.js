// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

function plan(ids, titles, currentIndex) {
    const empty = ids.map(id => !(titles[id]?.length > 0));
    const keep = empty.lastIndexOf(false) + 1;
    const remove = [];
    for (let i = ids.length - 1; i >= 0; i--) {
        if (empty[i] && i !== keep && i !== currentIndex) remove.push(ids[i]);
    }
    return { create: ids.length > 0 && !empty[ids.length - 1], remove };
}
