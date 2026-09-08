// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// Dot animations offered in the settings page, in display order.
// `id` is what gets stored in the config and read by Dot.qml.
// Each one has a silhouette of its own at panel size; variants that only differ in
// how they are drawn or eased look identical on a dot a few pixels across.
const MODES = [
    { id: "stretch", name: "Stretch", description: "Stretches into a pill towards the new desktop, then snaps back" },
    { id: "glide",   name: "Glide",   description: "Slides smoothly to the new desktop" },
    { id: "zip",     name: "Zip",     description: "Zips across as a fine line and snaps back into a dot" },
    { id: "elastic", name: "Elastic", description: "Tethered to the old desktop by a band that stretches, then snaps back" },
    { id: "spring",  name: "Spring",  description: "Slides over and wobbles into place like a spring" },
    { id: "hop",     name: "Hop",     description: "Jumps over in a little arc and squashes on landing" },
    { id: "swing",   name: "Swing",   description: "Swings over in a smooth arc, like a pendulum" },
    { id: "lift",    name: "Lift",    description: "Picked up, carried over, and set down on the new desktop" },
    { id: "glow",    name: "Glow",    description: "Glides over inside a soft glow that fades as it lands" },
    { id: "ripple",  name: "Ripple",  description: "Glides over, and a ring ripples out where it lands" },
    { id: "footprints", name: "Footprints", description: "Glides over, leaving a fading footprint on each desktop it passes" },
    { id: "ring",    name: "Ring",    description: "Opens out into a ring that fades from the old desktop, while a ring closes in and fills to a dot on the new one" },
    { id: "sparks",  name: "Sparks",  description: "Bursts into sparks that fly across, each on its own arc, and gather into a new dot" },
    { id: "pour",    name: "Pour",    description: "Drains from the old desktop into the new one down a thin stream, shrinking on one as it grows on the other" },
    { id: "drop",    name: "Drop",    description: "Falls away from the old desktop while a new dot drops onto the new one" },
    { id: "pop",     name: "Pop",     description: "Shrinks away and pops up at the new desktop" },
    { id: "fade",    name: "Fade",    description: "Cross-fades from the old desktop to the new one" },
    { id: "beam",    name: "Beam",    description: "Stretches into a tall thin beam that fades from the old desktop, while a beam appears on the new one and collapses into a dot" },
    { id: "split",   name: "Split",   description: "Splits into two half dots that swing out to either side, cross over, and merge again on the new desktop" },
    { id: "flash",   name: "Flash",   description: "Appears on the new desktop at once and blinks twice" },
    { id: "wrap",    name: "Wrap",    description: "Leaves past the end of the row and comes back in from the other end, the long way round" },
    { id: "steps",   name: "Steps",   description: "Jumps over in a few discrete stops, stop-motion style" },
    { id: "boomerang", name: "Boomerang", description: "Draws back a whole desktop away, then flies across and lands" },
    { id: "none",    name: "None",    description: "Jumps instantly" },
];
